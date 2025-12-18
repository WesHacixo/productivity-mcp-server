// Agent loop: plan → act → update memory → produce response
// Now uses ReasoningEngine for enterprise-grade reasoning
import Foundation

public actor Agent {
    private let memory: AgentMemory
    private let planner: AgentPlanner
    private let tools: ToolRegistry
    private let reasoningEngine: ReasoningEngine
    private let knowledgeEscort: KnowledgeEscort
    
    private let defaultPolicy = ToolPolicy(
        allowNetwork: true,
        allowFileIO: true,
        allowedDomains: ["api.github.com", "example.com"],
        allowedPaths: ["Documents", "Library"],
        maxResponseBytes: 256 * 1024
    )
    
    public init(
        memory: AgentMemory,
        planner: AgentPlanner,
        tools: ToolRegistry,
        reasoningEngine: ReasoningEngine,
        knowledgeEscort: KnowledgeEscort
    ) {
        self.memory = memory
        self.planner = planner
        self.tools = tools
        self.reasoningEngine = reasoningEngine
        self.knowledgeEscort = knowledgeEscort
    }
    
    /// Handle user input with sophisticated reasoning
    public func handle(userInput: String) async throws -> [AgentMessage] {
        let userMsg = AgentMessage(role: .user, content: userInput, timestamp: Date())
        await memory.append(userMsg)
        
        // Use reasoning engine for sophisticated planning and execution
        let result = try await reasoningEngine.reason(about: userInput)
        
        // Return messages from reasoning result
        return result.messages
    }
    
    /// Answer a question using knowledge escort
    public func answer(_ question: String) async throws -> KnowledgeAnswer {
        let context = ReasoningContext(
            entities: [],
            intent: .analyze,
            temporalContext: .now,
            userPreferences: UserPreferences()
        )
        return await knowledgeEscort.answer(question, context: context)
    }
}
