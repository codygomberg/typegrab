cask "typegrab" do
  version "0.1.3"
  sha256 "46a750c67ec1a9616ea86b127a66e5efe04eb7840479773fc0a4125660a8f66e"

  url "https://github.com/codygomberg/typegrab/releases/download/v#{version}/TypeGrab.dmg"
  name "TypeGrab"
  desc "Menu-bar OCR tool that grabs text from anything on your screen"
  homepage "https://github.com/codygomberg/typegrab"

  app "TypeGrab.app"
end
