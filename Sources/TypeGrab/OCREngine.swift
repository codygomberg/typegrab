import Vision
import Foundation

enum OCREngine {
    static func recognize(image: CGImage, completion: @escaping (String?) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let results = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            completion(TextAssembler.assemble(observations: results))
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        if #available(macOS 13.0, *) {
            request.automaticallyDetectsLanguage = true
        }

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(nil)
            }
        }
    }
}

enum TextAssembler {
    private struct Line {
        let text: String
        let top: CGFloat
        let bottom: CGFloat
        let height: CGFloat
        let minX: CGFloat
    }

    static func assemble(observations: [VNRecognizedTextObservation]) -> String {
        let raw: [Line] = observations.compactMap { obs in
            guard let s = obs.topCandidates(1).first?.string, !s.isEmpty else { return nil }
            return Line(
                text: s,
                top: obs.boundingBox.maxY,
                bottom: obs.boundingBox.minY,
                height: obs.boundingBox.height,
                minX: obs.boundingBox.minX
            )
        }

        // Sort top-to-bottom; ties (same visual row) left-to-right.
        let lines = raw.sorted { a, b in
            let sameRow = abs(a.bottom - b.bottom) < min(a.height, b.height) * 0.3
            return sameRow ? a.minX < b.minX : a.bottom > b.bottom
        }

        guard !lines.isEmpty else { return "" }

        struct Group {
            var texts: [String]
            var leadingGapFactor: CGFloat
        }

        var groups: [Group] = [Group(texts: [lines[0].text], leadingGapFactor: 0)]

        for i in 1..<lines.count {
            let current = lines[i]
            let prev = lines[i - 1]
            let gap = prev.bottom - current.top
            let avgHeight = (current.height + prev.height) / 2
            let gapFactor = avgHeight > 0 ? gap / avgHeight : 0
            let isParagraphBreak = gapFactor > 0.75
            let isListItem = startsWithListMarker(current.text)

            if isParagraphBreak || isListItem {
                groups.append(Group(
                    texts: [current.text],
                    leadingGapFactor: max(gapFactor, 0)
                ))
            } else {
                groups[groups.count - 1].texts.append(current.text)
            }
        }

        var output = ""
        for (i, group) in groups.enumerated() {
            if i > 0 {
                output += group.leadingGapFactor > 1.3 ? "\n\n" : "\n"
            }
            output += join(lines: group.texts)
        }
        return output
    }

    private static func join(lines: [String]) -> String {
        var result = ""
        for (i, raw) in lines.enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if i == 0 || result.isEmpty {
                result = line
                continue
            }
            // Soft-hyphen / hyphenated wrap: "con-\ntinue" → "continue"
            if result.hasSuffix("-"),
               let next = line.first, next.isLowercase {
                result = String(result.dropLast()) + line
            } else {
                result += " " + line
            }
        }
        return result
    }

    // Bullets: • ◦ ▪ ▫ ‣ ⁃ · *  |  dashes: - – —  |  numbered: 1. 1) a. a) ii. IV)
    private static let listPrefixRegex: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: #"^(\d+[.)]|[a-zA-Z][.)]|[ivx]+[.)]|[IVX]+[.)]|[•◦▪▫‣⁃·∙*]|[-–—])\s+\S"#,
            options: []
        )
    }()

    private static func startsWithListMarker(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let re = listPrefixRegex else { return false }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        return re.firstMatch(in: trimmed, options: [], range: range) != nil
    }
}
