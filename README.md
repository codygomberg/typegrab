# TypeGrab

A lightweight macOS menu-bar app for grabbing text out of anything on your screen — YouTube videos, PDFs with non-selectable text, images, screenshots — via a snipping-tool-style region select. OCR runs on-device using Apple's Vision framework, and the result lands on your clipboard.

<!-- TODO: add screenshot or GIF here -->
<!-- ![TypeGrab in action](docs/demo.gif) -->

- **On-device OCR.** No network calls, no API keys, no cloud.
- **Menu-bar only.** No dock icon, no windows in your way.
- **Global hotkey.** Configurable; default is ⌃⌥⌘T.
- **Smart formatting.** Wrapped lines are rejoined into paragraphs; bullet and numbered lists are preserved.

## Privacy

TypeGrab processes everything locally on your Mac. There is no telemetry, no analytics, and no network code in the app — OCR is performed by Apple's on-device Vision framework. The only data that leaves the app is the recognized text you explicitly capture, which is written to your system clipboard.

## Install

### Pre-built release

Download the latest `TypeGrab.app.zip` from the [Releases](../../releases) page, unzip, and drag `TypeGrab.app` to `/Applications`.

Because the release is ad-hoc signed (not notarized), macOS Gatekeeper will block the first launch. To open it:

1. Right-click `TypeGrab.app` → **Open**.
2. Click **Open** in the dialog that appears.

You only need to do this once.

### Build from source

Requirements:

- macOS 13 (Ventura) or later
- Swift 5.9+ toolchain (Xcode 15 or the matching command-line tools)

```bash
./build.sh
open build/TypeGrab.app
```

The script generates the app icon, builds a release binary, assembles a `.app` bundle in `build/`, and ad-hoc code-signs it so macOS remembers TCC permissions and `SMAppService` (launch-at-login) works.

## Usage

1. Launch `TypeGrab.app` — a menu-bar icon appears.
2. Press the hotkey (default **⌃⌥⌘T**) or choose **Capture Text** from the menu.
3. Drag a rectangle over the text you want.
4. Release — the recognized text is copied to your clipboard and a HUD confirms.

Open **Preferences…** from the menu to change the hotkey or toggle launch-at-login.

## Permissions

On first capture, macOS will prompt for **Screen Recording** permission (System Settings → Privacy & Security → Screen Recording). This is required to read pixels outside the app's own windows.

## Project layout

```
Sources/TypeGrab/     Swift sources (AppDelegate, OCREngine, SelectionOverlay, …)
Resources/Info.plist   App bundle metadata
Tools/MakeIcon.swift   Icon generator used by build.sh
build.sh               Build + bundle + ad-hoc sign
Package.swift          Swift Package manifest
```

## License

MIT — see [LICENSE](LICENSE).
