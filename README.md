# 🤖 aiUsageBar (`aiUsage`)

A 100% native macOS Menu Bar application built with **Swift & SwiftUI** for tracking AI token quota usage on **Google Antigravity (`agy`)**, Gemini, Claude, and GPT models.

![aiUsageBar Preview](assets/antigravity_logo_52.png)

## ✨ Features

- 🍏 **100% Native macOS SwiftUI App**: Built with AppKit & SwiftUI (`NSVisualEffectView` glass UI).
- ⚡ **Zero Latency**: Background cached execution (< 1ms UI response).
- 📊 **30-Day Token Usage Chart**: Sleek Emerald Green bar chart visualization matching Apple HIG aesthetics.
- 🎯 **Exact Menu Positioning**: Custom borderless floating panel (`CustomMenuPanel`) anchored precisely beneath the macOS Menu Bar.
- 📦 **Automated CI/CD Release**: Automatically compiled to `aiUsageBar.dmg` installers via GitHub Actions.

---

## 🍺 Installation via Homebrew Cask

Install directly from your Mac terminal in 1 command:

```bash
brew tap MFarisA/tap
brew install --cask aiusagebar
```

To update in the future:
```bash
brew upgrade aiusagebar
```

---

## 💾 Alternative: Manual `.dmg` Download

1. Go to [GitHub Releases](https://github.com/MFarisA/aiUsage/releases).
2. Download the latest `aiUsageBar.dmg`.
3. Double click `aiUsageBar.dmg` and **drag `aiUsageBar.app` into your Applications folder**.

---

## 🛠️ Building From Source Locally

```bash
git clone https://github.com/MFarisA/aiUsage.git
cd aiUsage
chmod +x build.sh
./build.sh
open aiUsageBar.app
```

---

## 🤖 GitHub Actions Workflow

This repository includes `.github/workflows/release.yml`. Whenever code is pushed to `main` or a new tag (`v1.0.0`) is created:
1. GitHub Actions spins up a macOS runner.
2. Compiles `aiUsageBar.app` using `swiftc`.
3. Packages a custom styled `aiUsageBar.dmg` disk image with a drag-and-drop link to `/Applications`.
4. Automatically publishes `aiUsageBar.dmg` to the GitHub Releases page!

---

## 📜 License

[MIT License](LICENSE) © MFarisA
