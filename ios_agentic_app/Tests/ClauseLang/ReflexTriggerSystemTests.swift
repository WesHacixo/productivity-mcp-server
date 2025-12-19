// Unit tests for ReflexTriggerSystem
import XCTest
@testable import ProductivityAgenticApp

final class ReflexTriggerSystemTests: XCTestCase {
    var clauseLang: ClauseLang!
    var dagBuilder: DAGBuilder!
    var reflexSystem: ReflexTriggerSystem!
    
    override func setUp() async throws {
        clauseLang = ClauseLang()
        dagBuilder = DAGBuilder(clauseLang: clauseLang)
        reflexSystem = ReflexTriggerSystem(clauseLang: clauseLang, dagBuilder: dagBuilder)
    }
    
    func testRegisterTriggers() async {
        // Create KO with reflex triggers
        let reflex = ReflexTriggers(
            triggerMap: [
                "calendar_conflict_detected": "resolve_conflict_clause",
                "user_edits_block": "learn_preference_clause"
            ]
        )
        
        let ko = KernelObject(
            clauseId: "test_ko",
            type: .scheduling,
            role: .agent,
            inputs: [],
            yields: [],
            dagNodes: [],
            logic: ClauseLogic(),
            reflex: reflex
        )
        
        await reflexSystem.registerTriggers(from: ko)
        
        // Triggers should be registered
        // (Can't directly test private state, but can test via handleEvent)
    }
    
    func testHandleConflictEvent() async throws {
        // Register triggers
        let reflex = ReflexTriggers(
            triggerMap: [
                "calendar_conflict_detected": "resolve_conflict_clause"
            ]
        )
        
        let ko = KernelObject(
            clauseId: "test_ko",
            type: .scheduling,
            role: .agent,
            inputs: [],
            yields: [],
            dagNodes: [],
            logic: ClauseLogic(),
            reflex: reflex
        )
        
        await reflexSystem.registerTriggers(from: ko)
        
        // Create conflict event
        let event = ReflexEvent(
            type: "calendar_conflict_detected",
            data: ["affected_blocks": "block1,block2"]
        )
        
        let context = ClauseContext()
        let result = try await reflexSystem.handleEvent(event, context: context, currentKO: ko)
        
        XCTAssertTrue(result.triggered)
        XCTAssertNotNil(result.adaptedKO)
        XCTAssertNotNil(result.reflexState)
    }
    
    func testHandleUserEditEvent() async throws {
        // Register triggers
        let reflex = ReflexTriggers(
            triggerMap: [
                "user_edits_block": "learn_preference_clause"
            ]
        )
        
        let ko = KernelObject(
            clauseId: "test_ko",
            type: .scheduling,
            role: .agent,
            inputs: [],
            yields: [],
            dagNodes: [],
            logic: ClauseLogic(),
            reflex: reflex
        )
        
        await reflexSystem.registerTriggers(from: ko)
        
        let event = ReflexEvent(
            type: "user_edits_block",
            data: ["block_id": "block1", "user_changes": "moved_to_afternoon"]
        )
        
        let context = ClauseContext()
        let result = try await reflexSystem.handleEvent(event, context: context, currentKO: ko)
        
        XCTAssertTrue(result.triggered)
        // Should learn preference, not reshuffle entire day
        if let adapted = result.adaptedKO {
            // Should have learning node, not full reshuffle
            XCTAssertTrue(adapted.dagNodes.contains { $0.clause.raw.contains("learn_preference") })
        }
    }
    
    func testUnknownEvent() async throws {
        let event = ReflexEvent(type: "unknown_event")
        let context = ClauseContext()
        let result = try await reflexSystem.handleEvent(event, context: context, currentKO: nil)
        
        XCTAssertFalse(result.triggered)
        XCTAssertTrue(result.message.contains("No trigger registered"))
    }
}
