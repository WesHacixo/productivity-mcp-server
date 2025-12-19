// Unit tests for KOExecutor
import XCTest
@testable import ProductivityAgenticApp

final class KOExecutorTests: XCTestCase {
    var clauseLang: ClauseLang!
    var koExecutor: KOExecutor!
    var dagBuilder: DAGBuilder!
    
    override func setUp() async throws {
        clauseLang = ClauseLang()
        dagBuilder = DAGBuilder(clauseLang: clauseLang)
        koExecutor = KOExecutor(clauseLang: clauseLang)
    }
    
    func testExecuteSimpleKO() async throws {
        // Create simple KO with one node
        let clause = ClauseInput(
            id: "clause1",
            rawClause: "WHEN x == 5 THEN set(y, 10)",
            outputs: ["y"]
        )
        
        let dagNodes = try await dagBuilder.buildDAG(from: [clause])
        
        let ko = await dagBuilder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "simple_ko",
            type: .workflow,
            role: .agent,
            inputs: ["x"],
            yields: ["y"]
        )
        
        let context = ClauseContext()
        context.variables["x"] = .number(5)
        
        let result = try await koExecutor.execute(ko, context: context)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.executionState.completedNodes.count, 1)
        XCTAssertEqual(result.executionState.iteration, 0)
    }
    
    func testExecuteKOWithDependencies() async throws {
        // Create KO with dependent nodes
        let clause1 = ClauseInput(
            id: "clause1",
            rawClause: "WHEN x > 0 THEN set(a, 1)",
            outputs: ["a"]
        )
        
        let clause2 = ClauseInput(
            id: "clause2",
            rawClause: "WHEN a == 1 THEN set(b, 2)",
            dependencies: ["clause1"],
            inputs: ["a"],
            outputs: ["b"]
        )
        
        let dagNodes = try await dagBuilder.buildDAG(from: [clause1, clause2])
        
        let ko = await dagBuilder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "dependent_ko",
            type: .workflow,
            role: .agent,
            inputs: ["x"],
            yields: ["b"]
        )
        
        let context = ClauseContext()
        context.variables["x"] = .number(5)
        
        let result = try await koExecutor.execute(ko, context: context)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.executionState.completedNodes.count, 2)
    }
    
    func testExitCondition() async throws {
        // Create KO with exit condition
        let clause = ClauseInput(
            id: "clause1",
            rawClause: "WHEN x == 5 THEN set(done, true)",
            outputs: ["done"]
        )
        
        let dagNodes = try await dagBuilder.buildDAG(from: [clause])
        
        let loop = LoopControl(
            bounds: 10,
            exitConditions: ["done == true"]
        )
        
        let ko = await dagBuilder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "exit_ko",
            type: .workflow,
            role: .agent,
            inputs: ["x"],
            yields: ["done"],
            loop: loop
        )
        
        let context = ClauseContext()
        context.variables["x"] = .number(5)
        
        let result = try await koExecutor.execute(ko, context: context)
        
        // Should exit early due to exit condition
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.executionState.events.contains { $0.type == .exitConditionMet })
    }
    
    func testMaxIterations() async throws {
        // Create KO that will hit max iterations
        let clause = ClauseInput(
            id: "clause1",
            rawClause: "WHEN x == 5 THEN set(x, 6)", // Changes x, won't complete
            outputs: ["x"]
        )
        
        let dagNodes = try await dagBuilder.buildDAG(from: [clause])
        
        let loop = LoopControl(
            bounds: 3, // Low bound
            exitConditions: ["never == true"] // Never true
        )
        
        let ko = await dagBuilder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "iter_ko",
            type: .workflow,
            role: .agent,
            inputs: ["x"],
            yields: ["x"],
            loop: loop
        )
        
        let context = ClauseContext()
        context.variables["x"] = .number(5)
        
        let result = try await koExecutor.execute(ko, context: context)
        
        // Should fail due to max iterations
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.error?.contains("Max iterations") ?? false)
    }
}
