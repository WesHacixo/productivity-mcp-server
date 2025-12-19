// Unit tests for DAGBuilder
import XCTest
@testable import ProductivityAgenticApp

final class DAGBuilderTests: XCTestCase {
    var clauseLang: ClauseLang!
    var dagBuilder: DAGBuilder!
    
    override func setUp() async throws {
        clauseLang = ClauseLang()
        dagBuilder = DAGBuilder(clauseLang: clauseLang)
    }
    
    // MARK: - DAG Building Tests
    
    func testBuildDAGWithExplicitDependencies() async throws {
        // Create clauses with explicit dependencies
        let clause1 = ClauseInput(
            id: "clause1",
            rawClause: "WHEN notes_count > 0 THEN normalize_fragments",
            inputs: ["notes.fragment[]"],
            outputs: ["normalized_ready"]
        )
        
        let clause2 = ClauseInput(
            id: "clause2",
            rawClause: "WHEN normalized_ready == true THEN cluster_by_intent",
            dependencies: ["clause1"],
            inputs: ["normalized_ready"],
            outputs: ["clusters_ready"]
        )
        
        let clause3 = ClauseInput(
            id: "clause3",
            rawClause: "WHEN clusters_ready == true THEN rank_by_flow_cost",
            dependencies: ["clause2"],
            inputs: ["clusters_ready"],
            outputs: ["ranked_ready"]
        )
        
        let dagNodes = try await dagBuilder.buildDAG(from: [clause1, clause2, clause3])
        
        XCTAssertEqual(dagNodes.count, 3)
        XCTAssertEqual(dagNodes[0].id, "clause1") // First in topological order
        XCTAssertEqual(dagNodes[1].id, "clause2")
        XCTAssertEqual(dagNodes[2].id, "clause3")
        
        // Check dependencies
        XCTAssertTrue(dagNodes[0].dependencies.isEmpty)
        XCTAssertEqual(dagNodes[1].dependencies, ["clause1"])
        XCTAssertEqual(dagNodes[2].dependencies, ["clause2"])
    }
    
    func testBuildDAGFromYields() async throws {
        // Test automatic dependency inference from yields/inputs
        let clause1 = ClauseInput(
            id: "clause1",
            rawClause: "WHEN notes_count > 0 THEN normalize_fragments",
            inputs: ["notes.fragment[]"],
            outputs: ["normalized_ready"]
        )
        
        let clause2 = ClauseInput(
            id: "clause2",
            rawClause: "WHEN normalized_ready == true THEN cluster_by_intent",
            inputs: ["normalized_ready"], // Depends on clause1's output
            outputs: ["clusters_ready"]
        )
        
        let dagNodes = try await dagBuilder.buildDAGFromYields(
            clauses: [clause1, clause2],
            yields: ["clusters_ready"],
            inputs: ["notes.fragment[]"]
        )
        
        XCTAssertEqual(dagNodes.count, 2)
        // clause2 should depend on clause1 (inferred from inputs/outputs)
        XCTAssertTrue(dagNodes[1].dependencies.contains("clause1"))
    }
    
    func testCycleDetection() async throws {
        // Create cyclic dependencies
        let clause1 = ClauseInput(
            id: "clause1",
            rawClause: "WHEN x == true THEN set_y",
            dependencies: ["clause2"], // Depends on clause2
            outputs: ["y"]
        )
        
        let clause2 = ClauseInput(
            id: "clause2",
            rawClause: "WHEN y == true THEN set_x",
            dependencies: ["clause1"], // Depends on clause1 (cycle!)
            outputs: ["x"]
        )
        
        // Should throw cyclic dependency error
        do {
            _ = try await dagBuilder.buildDAG(from: [clause1, clause2])
            XCTFail("Should have thrown cyclic dependency error")
        } catch DAGBuilderError.cyclicDependency {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testMissingDependency() async throws {
        // Create clause with missing dependency
        let clause1 = ClauseInput(
            id: "clause1",
            rawClause: "WHEN x == true THEN do_something",
            dependencies: ["nonexistent"], // Missing dependency
            outputs: ["result"]
        )
        
        // Should throw missing dependency error
        do {
            _ = try await dagBuilder.buildDAG(from: [clause1])
            XCTFail("Should have thrown missing dependency error")
        } catch DAGBuilderError.missingDependency {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTopologicalSort() async throws {
        // Create clauses in wrong order
        let clause3 = ClauseInput(
            id: "clause3",
            rawClause: "WHEN c == true THEN do_c",
            dependencies: ["clause2"],
            outputs: ["result"]
        )
        
        let clause1 = ClauseInput(
            id: "clause1",
            rawClause: "WHEN a == true THEN do_a",
            outputs: ["b"]
        )
        
        let clause2 = ClauseInput(
            id: "clause2",
            rawClause: "WHEN b == true THEN do_b",
            dependencies: ["clause1"],
            outputs: ["c"]
        )
        
        let dagNodes = try await dagBuilder.buildDAG(from: [clause3, clause1, clause2])
        
        // Should be sorted: clause1, clause2, clause3
        XCTAssertEqual(dagNodes[0].id, "clause1")
        XCTAssertEqual(dagNodes[1].id, "clause2")
        XCTAssertEqual(dagNodes[2].id, "clause3")
    }
    
    // MARK: - Operad Collapse Tests
    
    func testCollapseToKO() async throws {
        let clause1 = ClauseInput(
            id: "clause1",
            rawClause: "WHEN x > 0 THEN do_x",
            outputs: ["y"]
        )
        
        let clause2 = ClauseInput(
            id: "clause2",
            rawClause: "WHEN y == true THEN do_y",
            dependencies: ["clause1"],
            inputs: ["y"],
            outputs: ["result"]
        )
        
        let dagNodes = try await dagBuilder.buildDAG(from: [clause1, clause2])
        
        let ko = await dagBuilder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "test_ko",
            type: .workflow,
            role: .agent,
            inputs: ["x"],
            yields: ["result"]
        )
        
        XCTAssertEqual(ko.clauseId, "test_ko")
        XCTAssertEqual(ko.type, .workflow)
        XCTAssertEqual(ko.role, .agent)
        XCTAssertEqual(ko.inputs, ["x"])
        XCTAssertEqual(ko.yields, ["result"])
        XCTAssertEqual(ko.dagNodes.count, 2)
        XCTAssertEqual(ko.logic.conditions.count, 2) // One per node
        XCTAssertEqual(ko.logic.actions.count, 2) // One per node
    }
}
