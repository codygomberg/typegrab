cask "typegrab" do
  version "0.1.1"
  sha256 "7b96ce3931b127b249254d9057b516960bed8f442cf0458bd9f9ed70abbc15a7"

  url "https://github.com/codygomberg/typegrab/releases/download/v#{version}/TypeGrab.dmg"
  name "TypeGrab"
  desc "Menu-bar OCR tool that grabs text from anything on your screen"
  homepage "https://github.com/codygomberg/typegrab"

  app "TypeGrab.app"
end
