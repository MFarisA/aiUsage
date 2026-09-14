cask "aiusagebar" do
  version "1.0.0"
  sha256 "f0e7026f57e0f2ca23039dd7fd149789f4d7244748376dde704d15199ebb37b3"

  url "https://github.com/MFarisA/aiUsage/releases/download/v#{version}/aiUsageBar.dmg"
  name "aiUsageBar"
  desc "Native macOS SwiftUI Menu Bar AI token usage tracker"
  homepage "https://github.com/MFarisA/aiUsage"

  app "aiUsageBar.app"

  postflight do
    system_command "xattr",
                   args: ["-d", "com.apple.quarantine", "#{appdir}/aiUsageBar.app"],
                   sudo: false
  rescue
    nil
  end

  zap trash: [
    "~/Library/Preferences/com.mfarisa.aiUsageBar.plist",
  ]
end
