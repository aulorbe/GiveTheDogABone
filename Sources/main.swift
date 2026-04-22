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
    
    static let updateIntervalSeconds: TimeInterval = 60 // Poll every 60 seconds
}

// MARK: - Notion API Models
struct NotionDatabase: Codable {
    let results: [NotionPage]
}

struct NotionPage: Codable {
    let properties: [String: NotionProperty]
}

struct NotionProperty: Codable {
    let checkbox: CheckboxValue?
    
    struct CheckboxValue: Codable {
        let value: Bool?
        
        enum CodingKeys: String, CodingKey {
            case value = "checkbox"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            value = try? container.decode(Bool.self)
        }
    }
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
            // Look for common checkbox property names
            for (_, property) in page.properties {
                if let checkboxValue = property.checkbox?.value, checkboxValue {
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
    
    private func updateMenuBar() async {
        do {
            let stats = try await notionClient.fetchTodoStats()
            let percentage = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0.0
            let progressBar = generateColorfulProgressBar(percentage: percentage)
            
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
    
    private func generateColorfulProgressBar(percentage: Double) -> String {
        let totalBlocks = 10
        let filledBlocks = Int(percentage * Double(totalBlocks))
        
        // Rainbow colors based on progress
        let colors = ["🟥", "🟧", "🟨", "🟩", "🟦", "🟪"]
        let emptyBlock = "⬜"
        
        var bar = ""
        for i in 0..<totalBlocks {
            if i < filledBlocks {
                let colorIndex = min(Int((Double(i) / Double(totalBlocks)) * Double(colors.count)), colors.count - 1)
                bar += colors[colorIndex]
            } else {
                bar += emptyBlock
            }
        }
        
        return bar
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
