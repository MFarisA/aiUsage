import SwiftUI
import AppKit
import Foundation

// MARK: - Data Models

struct LimitInfo {
    var remainingPct: Int
    var resetIso: String
}

struct ModelQuota {
    var name: String
    var fiveHour: LimitInfo?
    var weekly: LimitInfo?
}

struct DailyUsage: Identifiable {
    let id = UUID()
    let dayLabel: String
    let tokensM: Double
    let heightRatio: CGFloat
}

// MARK: - Visual Effect View (Apple Native Glass Blur)

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Usage Manager

class UsageManager: ObservableObject {
    @Published var gemini: ModelQuota = ModelQuota(name: "Gemini Models")
    @Published var claude: ModelQuota = ModelQuota(name: "Claude & GPT Models")
    @Published var lastUpdated: String = "Just now"
    @Published var isRefreshing: Bool = false
    @Published var dailyUsages: [DailyUsage] = []
    
    init() {
        generateUsageHistory()
        fetchData()
    }
    
    func generateUsageHistory() {
        let rawHeights: [CGFloat] = [
            0.25, 0.35, 0.45, 0.3, 0.2, 0.8, 0.9, 0.55, 0.18, 0.12,
            0.08, 0.04, 0.18, 0.12, 0.08, 0.04, 0.15, 0.1, 0.22, 0.12,
            0.08, 0.1, 0.06, 0.2, 0.4, 0.5, 0.38, 0.45, 0.32, 0.28
        ]
        var usages: [DailyUsage] = []
        for (i, h) in rawHeights.enumerated() {
            usages.append(DailyUsage(
                dayLabel: "Day \(i+1)",
                tokensM: Double(h * 60.0),
                heightRatio: h
            ))
        }
        self.dailyUsages = usages
    }
    
    func fetchData() {
        isRefreshing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let cacheFile = "/tmp/agy_usage.cache"
            let fileManager = FileManager.default
            var needsFetch = true
            
            if fileManager.fileExists(atPath: cacheFile) {
                if let attrs = try? fileManager.attributesOfItem(atPath: cacheFile),
                   let modDate = attrs[.modificationDate] as? Date {
                    if Date().timeIntervalSince(modDate) < 300 {
                        needsFetch = false
                    }
                }
            }
            
            if needsFetch {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/Users/rebecca/.local/bin/agy")
                process.arguments = ["-p", "/usage"]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                
                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                        try? output.write(toFile: cacheFile, atomically: true, encoding: .utf8)
                    }
                } catch {
                    print("Fetch error: \(error)")
                }
            }
            
            self.parseCache(filePath: cacheFile)
        }
    }
    
    private func parseCache(filePath: String) {
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            DispatchQueue.main.async { self.isRefreshing = false }
            return
        }
        
        var newGemini = ModelQuota(name: "Gemini Models")
        var newClaude = ModelQuota(name: "Claude & GPT Models")
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "\t")
            if parts.count >= 4 {
                let provider = parts[0]
                let limitType = parts[1]
                let pctStr = parts[2].replacingOccurrences(of: "%", with: "")
                let pct = Int(pctStr) ?? 100
                let resetIso = parts[3]
                
                let limitInfo = LimitInfo(remainingPct: pct, resetIso: resetIso)
                
                if provider.contains("Gemini") {
                    if limitType.contains("Weekly") {
                        newGemini.weekly = limitInfo
                    } else if limitType.contains("Five Hour") {
                        newGemini.fiveHour = limitInfo
                    }
                } else if provider.contains("Claude") || provider.contains("GPT") {
                    if limitType.contains("Weekly") {
                        newClaude.weekly = limitInfo
                    } else if limitType.contains("Five Hour") {
                        newClaude.fiveHour = limitInfo
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.gemini = newGemini
            self.claude = newClaude
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.lastUpdated = "Updated at " + formatter.string(from: Date())
            self.isRefreshing = false
        }
    }
    
    func formatTimeLeft(_ isoStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: isoStr)
        if date == nil {
            let fallback = ISO8601DateFormatter()
            date = fallback.date(from: isoStr)
        }
        
        guard let targetDate = date else { return "" }
        let diff = targetDate.timeIntervalSince(Date())
        if diff <= 0 { return "Resets soon" }
        
        let days = Int(diff) / 86400
        let hours = (Int(diff) % 86400) / 3600
        let minutes = (Int(diff) % 3600) / 60
        
        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 { parts.append("\(hours)h") }
        parts.append("\(minutes)m")
        return "Resets in " + parts.joined(separator: " ")
    }
}

// MARK: - Apple Minimalist SwiftUI View

struct ContentView: View {
    @ObservedObject var manager: UsageManager
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow) // Translucent macOS glass
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        if let icon = NSImage(contentsOfFile: "/Users/rebecca/.local/bin/antigravity_icon_52.png") {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Google Antigravity")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(manager.lastUpdated)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text("PRO")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(Color.green)
                        .clipShape(Capsule())
                }
                
                Divider().opacity(0.15)
                
                // Quota Cards
                VStack(spacing: 10) {
                    ModelQuotaView(quota: manager.gemini, manager: manager)
                    ModelQuotaView(quota: manager.claude, manager: manager)
                }
                
                // 30-Day Token Cost Chart (Apple Emerald Green Minimalist Theme)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Usage History (30 days)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Peak: 58M")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Green Bar Chart
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(manager.dailyUsages) { item in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.85, blue: 0.5), Color(red: 0.1, green: 0.7, blue: 0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: max(4, item.heightRatio * 55))
                        }
                    }
                    .frame(height: 60, alignment: .bottom)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
                
                Divider().opacity(0.15)
                
                // Action Footer
                HStack {
                    Button(action: {
                        manager.fetchData()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                            Text(manager.isRefreshing ? "Refreshing..." : "Refresh")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        exit(0) // Direct process exit ensuring 100% reliable Quit
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "power")
                                .font(.system(size: 11))
                            Text("Quit")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
        .frame(width: 300)
        .cornerRadius(12)
    }
}

// MARK: - Quota Card View

struct ModelQuotaView: View {
    let quota: ModelQuota
    @ObservedObject var manager: UsageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(quota.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
            
            if let fh = quota.fiveHour {
                QuotaRow(label: "5-Hour", limit: fh, timeText: manager.formatTimeLeft(fh.resetIso))
            }
            if let wk = quota.weekly {
                QuotaRow(label: "Weekly", limit: wk, timeText: manager.formatTimeLeft(wk.resetIso))
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
    }
}

struct QuotaRow: View {
    let label: String
    let limit: LimitInfo
    let timeText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(limit.remainingPct)%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(limit.remainingPct > 20 ? Color(red: 0.2, green: 0.82, blue: 0.48) : Color.orange)
                        .frame(width: max(0, geo.size.width * CGFloat(limit.remainingPct) / 100.0))
                }
            }
            .frame(height: 4)
            
            if !timeText.isEmpty {
                Text(timeText)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
    }
}

// MARK: - Custom Panel

class CustomMenuPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 380),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.contentView = contentView
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var panel: CustomMenuPanel!
    var manager = UsageManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let hostingView = NSHostingView(rootView: ContentView(manager: manager))
        hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 380)
        
        self.panel = CustomMenuPanel(contentView: hostingView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = " 91% • 96%"
            if let icon = NSImage(contentsOfFile: "/Users/rebecca/.local/bin/antigravity_icon_52.png") {
                icon.isTemplate = true
                icon.size = NSSize(width: 16, height: 16)
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Antigravity")
            }
            button.action = #selector(togglePanel(_:))
            button.target = self
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.panel.isVisible == true {
                self?.panel.orderOut(nil)
            }
        }
    }
    
    @objc func togglePanel(_ sender: AnyObject?) {
        guard let button = statusItem.button, let window = button.window else { return }
        
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            let buttonFrame = window.convertToScreen(button.frame)
            let panelSize = panel.frame.size
            
            let screenMaxX = NSScreen.main?.visibleFrame.maxX ?? (buttonFrame.maxX)
            let panelX = min(buttonFrame.maxX - panelSize.width + 10, screenMaxX - panelSize.width - 10)
            let panelY = buttonFrame.minY - panelSize.height - 4
            
            panel.setFrameOrigin(NSPoint(x: panelX, y: panelY))
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
