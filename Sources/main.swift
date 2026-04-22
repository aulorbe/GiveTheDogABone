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
