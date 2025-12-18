// Context manager: maintains conversation and knowledge context
import Foundation

public actor ContextManager {
    private var activeContexts: [UUID: ActiveContext] = [:]
    private var contextHistory: [ContextSnapshot] = []
    
    public init() {}
    
    /// Update context with new knowledge and reasoning trace
    public func updateContext(
        query: String,
        knowledge: [KnowledgeItem],
        trace: ReasoningTrace
    ) async {
        let contextId = UUID()
        let context = ActiveContext(
            id: contextId,
            query: query,
            knowledge: knowledge,
            reasoningTrace: trace,
            createdAt: Date()
        )
        
        activeContexts[contextId] = context
        
        // Create snapshot
        let snapshot = ContextSnapshot(
            context: context,
            timestamp: Date()
        )
        contextHistory.append(snapshot)
        
        // Prune old contexts (keep last 100)
        if contextHistory.count > 100 {
            contextHistory.removeFirst(contextHistory.count - 100)
        }
    }
    
    /// Get current context
    public func getCurrentContext() async -> ActiveContext? {
        activeContexts.values.max(by: { $0.createdAt < $1.createdAt })
    }
    
    /// Get context history
    public func getHistory(limit: Int = 20) async -> [ContextSnapshot] {
        Array(contextHistory.suffix(limit))
    }
    
    /// Find relevant contexts for a query
    public func findRelevantContexts(for query: String, limit: Int = 5) async -> [ActiveContext] {
        let relevant = activeContexts.values.filter { context in
            context.query.localizedCaseInsensitiveContains(query) ||
            context.knowledge.contains { $0.content.localizedCaseInsensitiveContains(query) }
        }
        
        return Array(relevant.prefix(limit))
    }
}

struct ActiveContext {
    let id: UUID
    let query: String
    let knowledge: [KnowledgeItem]
    let reasoningTrace: ReasoningTrace
    let createdAt: Date
}

struct ContextSnapshot {
    let context: ActiveContext
    let timestamp: Date
}
