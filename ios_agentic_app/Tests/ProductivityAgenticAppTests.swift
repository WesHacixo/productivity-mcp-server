import XCTest
@testable import ProductivityAgenticApp

final class ProductivityAgenticAppTests: XCTestCase {
    func testPlannerDefault() async throws {
        let planner = AgentPlanner()
        let plan = await planner.plan(for: "Hello agent", availableTools: [])
        XCTAssertEqual(plan.steps.count, 1)
        XCTAssertNil(plan.steps.first?.toolName)
    }
    
    func testFilesToolRejectsPath() async throws {
        let tool = FilesTool()
        let policy = ToolPolicy(allowFileIO: true, allowedPaths: ["Documents"])
        do {
            _ = try await tool.call(args: ["path": "Library/foo.txt", "content": "hi"], policy: policy)
            XCTFail("Should have thrown")
        } catch {
            // Expected to throw
        }
    }
    
    func testHTTPToolRejectsDisallowedDomain() async throws {
        let tool = HTTPTool()
        let policy = ToolPolicy(
            allowNetwork: true,
            allowedDomains: ["example.com"]
        )
        do {
            _ = try await tool.call(args: ["url": "https://malicious.com/data"], policy: policy)
            XCTFail("Should have thrown")
        } catch {
            // Expected to throw
        }
    }
}
