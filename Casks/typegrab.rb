cask "typegrab" do
  version "0.1.2"
  sha256 "21cbaca8173d05997a84f35a2eb5e1fc2e295f7d0398f964cefddd0ca5040b46"

  url "https://github.com/codygomberg/typegrab/releases/download/v#{version}/TypeGrab.dmg"
  name "TypeGrab"
  desc "Menu-bar OCR tool that grabs text from anything on your screen"
  homepage "https://github.com/codygomberg/typegrab"

  app "TypeGrab.app"
end
