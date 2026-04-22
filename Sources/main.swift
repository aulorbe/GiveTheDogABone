import Cocoa
import Foundation

// MARK: - Configuration
struct NotionConfig {
    static var apiKey: String {
        ProcessInfo.processInfo.environment["NOTION_API_KEY"] ?? ""
    }
    
    static var databaseId: String {
        ProcessInfo.processInfo.environment["NOTION_DATABASE_ID"] ?? ""
    }
    
    static let updateIntervalSeconds: TimeInterval = 5 // Poll every 5 seconds for near-instant updates
}

// MARK: - Notion API Models
struct NotionDatabase: Codable {
    let results: [NotionPage]
}

struct NotionPage: Codable {
    let properties: [String: NotionProperty]
}

struct NotionProperty: Codable {
    let type: String?
    let checkbox: Bool?
}

// MARK: - Notion API Client
class NotionClient {
    func fetchTodoStats() async throws -> (completed: Int, total: Int) {
        let urlString = "https://api.notion.com/v1/databases/\(NotionConfig.databaseId)/query"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(NotionConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let database = try JSONDecoder().decode(NotionDatabase.self, from: data)

        var completed = 0
        let total = database.results.count

        for page in database.results {
            // Look for checkbox properties that are checked
            for (_, property) in page.properties {
                if property.type == "checkbox", let isChecked = property.checkbox, isChecked {
                    completed += 1
                    break
                }
            }
        }

        return (completed, total)
    }
}

// MARK: - Celebration Window
class CelebrationWindow: NSWindow {
    private var fireworksTimer: Timer?
    private var fireworkLabels: [NSTextField] = []

    init() {
        let screen = NSScreen.main?.frame ?? .zero
        super.init(
            contentRect: screen,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.backgroundColor = NSColor.black.withAlphaComponent(0.7)
        self.isOpaque = false
        self.level = .floating
        self.ignoresMouseEvents = false

        setupCelebration()
    }

    private func setupCelebration() {
        // Main message
        let messageLabel = NSTextField(labelWithString: "You rock! Nice job! 🎉")
        messageLabel.font = NSFont.systemFont(ofSize: 72, weight: .bold)
        messageLabel.textColor = .white
        messageLabel.alignment = .center
        messageLabel.frame = NSRect(
            x: 0,
            y: self.frame.height / 2 - 50,
            width: self.frame.width,
            height: 100
        )
        contentView?.addSubview(messageLabel)

        // Start fireworks
        startFireworks()

        // Auto-close after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.close()
        }

        // Click anywhere to close
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        contentView?.addGestureRecognizer(clickGesture)
    }

    @objc private func handleClick() {
        close()
    }

    private func startFireworks() {
        fireworksTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.launchFirework()
        }

        // Stop after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.fireworksTimer?.invalidate()
        }
    }

    private func launchFirework() {
        let emojis = ["🎆", "✨", "🎇", "💥", "⭐", "🌟"]
        let emoji = emojis.randomElement() ?? "🎆"

        let x = CGFloat.random(in: 100...(self.frame.width - 100))
        let startY = self.frame.height

        let firework = NSTextField(labelWithString: emoji)
        firework.font = NSFont.systemFont(ofSize: 48)
        firework.isBezeled = false
        firework.backgroundColor = .clear
        firework.frame = NSRect(x: x, y: startY, width: 60, height: 60)
        contentView?.addSubview(firework)
        fireworkLabels.append(firework)

        // Animate upward with fade
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 2.0
            firework.animator().alphaValue = 0
            firework.animator().frame = NSRect(
                x: x + CGFloat.random(in: -50...50),
                y: CGFloat.random(in: 200...600),
                width: 60,
                height: 60
            )
        }, completionHandler: {
            firework.removeFromSuperview()
        })
    }

    override func close() {
        fireworksTimer?.invalidate()
        super.close()
    }
}

// MARK: - Menu Bar App
class MenuBarApp: NSObject {
    private var statusItem: NSStatusItem!
    private let notionClient = NotionClient()
    private var timer: Timer?
    private var previousCompleted: Int = -1

    func start() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "Loading..."
        }

        // Create menu
        let menu = NSMenu()

        let refreshItem = NSMenuItem(title: "🔄 Refresh Now", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu

        // Initial fetch
        Task {
            await updateMenuBar()
        }

        // Start polling
        timer = Timer.scheduledTimer(withTimeInterval: NotionConfig.updateIntervalSeconds, repeats: true) { [weak self] _ in
            Task {
                await self?.updateMenuBar()
            }
        }
    }

    @objc private func refreshNow() {
        Task {
            await updateMenuBar()
        }
    }
    
    private func updateMenuBar() async {
        do {
            let stats = try await notionClient.fetchTodoStats()
            let progressBar = generateColorfulProgressBar(completed: stats.completed, total: stats.total)

            await MainActor.run {
                if let button = statusItem.button {
                    button.title = "\(progressBar) \(stats.completed)/\(stats.total)"
                }

                // Check if just completed all tasks (celebration time!)
                if stats.total > 0 && stats.completed == stats.total && previousCompleted != stats.total {
                    showCelebration()
                }

                previousCompleted = stats.completed
            }
        } catch {
            await MainActor.run {
                if let button = statusItem.button {
                    button.title = "❌ Error"
                }
            }
            print("Error fetching Notion data: \(error)")
        }
    }

    private func showCelebration() {
        let celebrationWindow = CelebrationWindow()
        celebrationWindow.makeKeyAndOrderFront(nil)
    }

    private func generateColorfulProgressBar(completed: Int, total: Int) -> String {
        guard total > 0 else { return "🐕" }

        // Dachshund that gets shorter as you complete tasks!
        let remaining = total - completed

        // Build the dachshund: head + body segments + tail
        let head = "🐕"
        let bodySegment = "━"
        let tail = "🦴"

        // The dog gets shorter as you complete more tasks
        // Start with a long body, shrink down to just the head!
        var body = ""
        for _ in 0..<remaining {
            body += bodySegment
        }

        // When all done, just show the happy dog with its bone!
        if remaining == 0 {
            return "\(head)\(tail)"
        }

        return "\(head)\(body)\(tail)"
    }
}

// MARK: - App Entry Point
class AppDelegate: NSObject, NSApplicationDelegate {
    let menuBarApp = MenuBarApp()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarApp.start()
    }
}

// Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
