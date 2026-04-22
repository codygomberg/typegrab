cask "typegrab" do
  version "0.1.0"
  sha256 "323eec8ec88793be9ca7c65e9513469241dbb131277b3c89e50df18e1eb5269c"

  url "https://github.com/codygomberg/typegrab/releases/download/v#{version}/TypeGrab.dmg"
  name "TypeGrab"
  desc "Menu-bar OCR tool that grabs text from anything on your screen"
  homepage "https://github.com/codygomberg/typegrab"

  app "TypeGrab.app"
end
