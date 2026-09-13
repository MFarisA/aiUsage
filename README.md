# 🤖 AntigravityBar (`aiUsage`)

A 100% native macOS Menu Bar application built with **Swift & SwiftUI** for tracking AI token quota usage on **Google Antigravity (`agy`)**, Gemini, Claude, and GPT models.

![AntigravityBar Preview](assets/antigravity_icon_52.png)

## ✨ Features

- 🍏 **100% Native macOS SwiftUI App**: Built with AppKit & SwiftUI (`NSVisualEffectView` glass UI).
- ⚡ **Zero Latency**: Background cached execution (< 1ms UI response).
- 📊 **30-Day Token Usage Chart**: Sleek Emerald Green bar chart visualization matching Apple HIG aesthetics.
- 🎯 **Exact Menu Positioning**: Custom borderless floating panel (`CustomMenuPanel`) anchored precisely beneath the macOS Menu Bar.
- 📦 **Automated CI/CD Release**: Automatically compiled to `.dmg` installers via GitHub Actions.

---

## 💾 Installation

### Download Ready-to-use `.dmg` Installer

1. Go to [GitHub Releases](https://github.com/MFarisA/aiUsage/releases).
2. Download the latest `AntigravityBar.dmg`.
3. Double click `AntigravityBar.dmg` and **drag `AntigravityBar.app` into your Applications folder**.

---

## 🛠️ Building From Source Locally

```bash
git clone https://github.com/MFarisA/aiUsage.git
cd aiUsage
chmod +x build.sh
./build.sh
open AntigravityBar.app
```

---

## 🤖 GitHub Actions Workflow

This repository includes `.github/workflows/release.yml`. Whenever code is pushed to `main` or a new tag (`v1.0.0`) is created:
1. GitHub Actions spins up a macOS runner.
2. Compiles `AntigravityBar.app` using `swiftc`.
3. Packages a native `.dmg` disk image with a drag-and-drop link to `/Applications`.
4. Automatically publishes `AntigravityBar.dmg` to the GitHub Releases page!

---

## 📜 License

[MIT License](LICENSE) © MFarisA
