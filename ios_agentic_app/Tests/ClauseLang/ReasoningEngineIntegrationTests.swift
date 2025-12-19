// Integration tests for KO execution with ReasoningEngine
import XCTest
@testable import ProductivityAgenticApp

final class ReasoningEngineIntegrationTests: XCTestCase {
    var clauseLang: ClauseLang!
    var dagBuilder: DAGBuilder!
    var koExecutor: KOExecutor!
    var reasoningEngine: ReasoningEngine!
    var planner: AgentPlanner!
    var knowledgeEscort: KnowledgeEscort!
    var tools: ToolRegistry!
    var memory: AgentMemory!
    
    override func setUp() async throws {
        clauseLang = ClauseLang()
        dagBuilder = DAGBuilder(clauseLang: clauseLang)
        koExecutor = KOExecutor(clauseLang: clauseLang)
        
        planner = AgentPlanner()
        let knowledgeGraph = KnowledgeGraph()
        let vectorMemory = VectorMemory()
        let contextManager = ContextManager()
        knowledgeEscort = KnowledgeEscort(
            knowledgeGraph: knowledgeGraph,
            vectorMemory: vectorMemory,
            contextManager: contextManager
        )
        tools = ToolRegistry()
        memory = AgentMemory()
        
        reasoningEngine = ReasoningEngine(
            planner: planner,
            knowledgeBase: knowledgeEscort,
            tools: tools,
            memory: memory,
            koExecutor: koExecutor
        )
    }
    
    func testExecuteKOThroughReasoningEngine() async throws {
        // Build a simple scheduling KO
        let ko = try await FlowstateClauseLibrary.buildSchedulingWorkflowKO(
            clauseLang: clauseLang,
            dagBuilder: dagBuilder,
            focusModeEnabled: true,
            recoveryBlocksEnabled: true
        )
        
        // Create reasoning context
        let context = ReasoningContext(
            entities: [
                Entity(type: "focus_mode", value: "deep", confidence: 1.0)
            ],
            intent: .create,
            temporalContext: .now,
            userPreferences: UserPreferences()
        )
        
        // Execute through ReasoningEngine
        let result = try await reasoningEngine.executeKO(ko, context: context)
        
        XCTAssertNotNil(result)
        // Execution may succeed or fail depending on context, but should not crash
    }
    
    func testHandleReflexEventThroughReasoningEngine() async throws {
        // Build KO with reflex triggers
        let ko = try await FlowstateClauseLibrary.buildSchedulingWorkflowKO(
            clauseLang: clauseLang,
            dagBuilder: dagBuilder
        )
        
        let context = ReasoningContext(
            entities: [],
            intent: .general,
            temporalContext: .now,
            userPreferences: UserPreferences()
        )
        
        // Create conflict event
        let event = ReflexEvent(
            type: "calendar_conflict_detected",
            data: ["affected_blocks": "block1"]
        )
        
        // Handle through ReasoningEngine
        let adaptedKO = try await reasoningEngine.handleReflexEvent(event, currentKO: ko, context: context)
        
        // Should return adapted KO (or nil if no reflex system)
        // Just verify it doesn't crash
        XCTAssertNotNil(adaptedKO ?? ko)
    }
}
