// Simple local memory: persistent store + vector index stub
import Foundation

public actor AgentMemory {
    private var messages: [AgentMessage] = []
    private let persistenceURL: URL
    
    public init(persistenceURL: URL? = nil) {
        if let url = persistenceURL {
            self.persistenceURL = url
        } else {
            self.persistenceURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("agent_memory.json")
        }
        Task { await load() }
    }
    
    public func append(_ msg: AgentMessage) async {
        messages.append(msg)
        await save()
    }
    
    public func recent(limit: Int = 50) async -> [AgentMessage] {
        Array(messages.suffix(limit))
    }
    
    public func searchBySubstring(_ q: String, limit: Int = 10) async -> [AgentMessage] {
        let hits = messages.filter { $0.content.localizedCaseInsensitiveContains(q) }
        return Array(hits.prefix(limit))
    }
    
    private func load() async {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoded = try JSONDecoder().decode([AgentMessage].self, from: data)
            messages = decoded
        } catch {
            // First run or corrupted file; start fresh
            messages = []
        }
    }
    
    private func save() async {
        do {
            let data = try JSONEncoder().encode(messages)
            try data.write(to: persistenceURL, options: [.atomic])
        } catch {
            // Non-fatal; caller can inspect later
        }
    }
}
