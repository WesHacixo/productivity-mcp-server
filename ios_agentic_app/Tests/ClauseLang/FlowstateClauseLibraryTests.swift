// Unit tests for FlowstateClauseLibrary
import XCTest
@testable import ProductivityAgenticApp

final class FlowstateClauseLibraryTests: XCTestCase {
    var clauseLang: ClauseLang!
    var dagBuilder: DAGBuilder!
    
    override func setUp() async throws {
        clauseLang = ClauseLang()
        dagBuilder = DAGBuilder(clauseLang: clauseLang)
    }
    
    func testFocusModeClauses() {
        let clauses = FlowstateClauseLibrary.focusModeClauses
        XCTAssertEqual(clauses.count, 3)
        XCTAssertTrue(clauses.allSatisfy { $0.contains("WHEN") && $0.contains("THEN") })
    }
    
    func testRecoveryBlockClauses() {
        let clauses = FlowstateClauseLibrary.recoveryBlockClauses
        XCTAssertEqual(clauses.count, 3)
    }
    
    func testMeetingShieldClauses() {
        let clauses = FlowstateClauseLibrary.meetingShieldClauses
        XCTAssertEqual(clauses.count, 3)
    }
    
    func testBuildSchedulingWorkflowKO() async throws {
        let ko = try await FlowstateClauseLibrary.buildSchedulingWorkflowKO(
            clauseLang: clauseLang,
            dagBuilder: dagBuilder,
            focusModeEnabled: true,
            recoveryBlocksEnabled: true,
            meetingShieldsEnabled: false,
            errandsBatchingEnabled: false,
            flowCostEnabled: false
        )
        
        XCTAssertEqual(ko.type, .scheduling)
        XCTAssertEqual(ko.role, .agent)
        XCTAssertNotNil(ko.loop)
        XCTAssertNotNil(ko.reflex)
        XCTAssertTrue(ko.dagNodes.count > 0)
        
        // Should have focus mode and recovery block clauses
        let clauseTexts = ko.dagNodes.map { $0.clause.raw }
        XCTAssertTrue(clauseTexts.contains { $0.contains("focus_mode") })
        XCTAssertTrue(clauseTexts.contains { $0.contains("recovery_block") })
    }
    
    func testCreateClauseInput() {
        let input = FlowstateClauseLibrary.createClauseInput(
            rawClause: "WHEN x == 5 THEN do_x",
            description: "Test clause",
            inputs: ["x"],
            outputs: ["result"]
        )
        
        XCTAssertEqual(input.rawClause, "WHEN x == 5 THEN do_x")
        XCTAssertEqual(input.description, "Test clause")
        XCTAssertEqual(input.inputs, ["x"])
        XCTAssertEqual(input.outputs, ["result"])
    }
    
    func testAllClauses() {
        let all = FlowstateClauseLibrary.allClauses
        XCTAssertTrue(all.count >= 24) // Should have all categories
    }
}
