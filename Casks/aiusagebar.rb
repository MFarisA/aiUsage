cask "aiusagebar" do
  version "1.0.0"
  sha256 "71d13cf6fe3ea929525d2126a19f06d2a2e68a547e28b823bb16abf0f9c85c66"

  url "https://github.com/MFarisA/aiUsage/releases/download/v#{version}/aiUsageBar.dmg"
  name "aiUsageBar"
  desc "Native macOS SwiftUI Menu Bar AI token usage tracker"
  homepage "https://github.com/MFarisA/aiUsage"

  app "aiUsageBar.app"

  zap trash: [
    "~/Library/Preferences/com.mfarisa.aiUsageBar.plist",
  ]
end
