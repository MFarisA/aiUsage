#!/bin/bash
set -e

APP_NAME="aiUsageBar"
APP_DIR="$APP_NAME.app"

echo "🔨 Building $APP_NAME native macOS SwiftUI application..."

# Clean old build
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Generate native macOS AppIcon.icns from square 1024x1024 master canvas
if [ -f "assets/app_icon_master.png" ]; then
    mkdir -p AppIcon.iconset
    SRC="assets/app_icon_master.png"

    sips -z 16 16     "$SRC" --out AppIcon.iconset/icon_16x16.png >/dev/null
    sips -z 32 32     "$SRC" --out AppIcon.iconset/icon_16x16@2x.png >/dev/null
    sips -z 32 32     "$SRC" --out AppIcon.iconset/icon_32x32.png >/dev/null
    sips -z 64 64     "$SRC" --out AppIcon.iconset/icon_32x32@2x.png >/dev/null
    sips -z 128 128   "$SRC" --out AppIcon.iconset/icon_128x128.png >/dev/null
    sips -z 256 256   "$SRC" --out AppIcon.iconset/icon_128x128@2x.png >/dev/null
    sips -z 256 256   "$SRC" --out AppIcon.iconset/icon_256x256.png >/dev/null
    sips -z 512 512   "$SRC" --out AppIcon.iconset/icon_256x256@2x.png >/dev/null
    sips -z 512 512   "$SRC" --out AppIcon.iconset/icon_512x512.png >/dev/null

    iconutil -c icns AppIcon.iconset -o "$APP_DIR/Contents/Resources/AppIcon.icns"
    rm -rf AppIcon.iconset
    cp "$APP_DIR/Contents/Resources/AppIcon.icns" assets/AppIcon.icns 2>/dev/null || true
fi

# Compile Swift code
swiftc -O \
    -target arm64-apple-macos12.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    src/main.swift \
    -o "$APP_DIR/Contents/MacOS/$APP_NAME"

# Create Info.plist with CFBundleIconFile
cat << EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.mfarisa.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF

echo "🔐 Ad-hoc code signing $APP_NAME.app..."
codesign --force --deep --sign - "$APP_DIR"

echo "✅ $APP_NAME.app built successfully with native un-distorted AppIcon.icns!"
