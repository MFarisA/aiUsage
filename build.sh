#!/bin/bash
set -e

APP_NAME="AntigravityBar"
APP_DIR="$APP_NAME.app"

echo "🔨 Building $APP_NAME native macOS SwiftUI application..."

# Clean old build
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Compile Swift code
swiftc -O \
    -target arm64-apple-macos12.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    src/main.swift \
    -o "$APP_DIR/Contents/MacOS/$APP_NAME"

# Copy Icon if exists
if [ -f "/Users/rebecca/.local/bin/antigravity_icon_52.png" ]; then
    cp "/Users/rebecca/.local/bin/antigravity_icon_52.png" "$APP_DIR/Contents/Resources/AppIcon.png"
fi

# Create Info.plist (LSUIElement = true hides Dock icon so it runs purely as a Menu Bar app!)
cat << 'EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AntigravityBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.rebecca.AntigravityBar</string>
    <key>CFBundleName</key>
    <string>AntigravityBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF

echo "✅ $APP_NAME.app built successfully!"
