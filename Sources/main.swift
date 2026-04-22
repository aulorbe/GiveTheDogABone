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

// MARK: - Menu Bar App
class MenuBarApp: NSObject {
    private var statusItem: NSStatusItem!
    private let notionClient = NotionClient()
    private var timer: Timer?
    private var isUpdating = false
    private var lastGoodTitle: String?

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
    
    private func log(_ message: String) {
        let logFile = "/tmp/notion-dog-bone.log"
        let timestamp = Date().formatted()
        let line = "[\(timestamp)] \(message)\n"
        if let data = line.data(using: .utf8) {
            if let handle = FileHandle(forWritingAtPath: logFile) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                try? data.write(to: URL(fileURLWithPath: logFile))
            }
        }
    }

    private func updateMenuBar() async {
        // Prevent concurrent updates
        guard !isUpdating else {
            log("⏭️ Skipping - update already in progress")
            return
        }

        isUpdating = true
        defer { isUpdating = false }

        do {
            log("🔄 Fetching from Notion...")
            let stats = try await notionClient.fetchTodoStats()
            log("✅ Got stats: \(stats.completed)/\(stats.total)")

            let progressBar = generateColorfulProgressBar(completed: stats.completed, total: stats.total)
            log("✅ Generated bar: \(progressBar)")

            await MainActor.run {
                if let button = statusItem.button {
                    let newTitle = "\(progressBar) \(stats.completed)/\(stats.total)"
                    button.title = newTitle
                    lastGoodTitle = newTitle
                    log("✅ Updated UI to: \(newTitle)")
                }
            }
        } catch {
            log("❌ API Error (keeping last good value): \(error.localizedDescription)")

            // Don't show error - keep last good value
            await MainActor.run {
                if let button = statusItem.button, lastGoodTitle == nil {
                    button.title = "🐕 Loading..."
                }
            }
        }
    }

    private func generateColorfulProgressBar(completed: Int, total: Int) -> String {
        // No tasks or all complete? Just show celebration!
        guard total > 0 else { return "🎉" }

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

        // When all done, just show celebration emoji!
        if remaining == 0 {
            return "🎉"
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
