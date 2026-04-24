cask "typegrab" do
  version "0.1.4"
  sha256 "e27b2a18c4280cb89cb63fd05930a4bfa19992d2b1e4748a18c02a0ef3404036"

  url "https://github.com/codygomberg/typegrab/releases/download/v#{version}/TypeGrab.dmg"
  name "TypeGrab"
  desc "Menu-bar OCR tool that grabs text from anything on your screen"
  homepage "https://github.com/codygomberg/typegrab"

  app "TypeGrab.app"
end
