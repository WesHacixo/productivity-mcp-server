// Tool protocol and registry with strict policy
import Foundation

public protocol AgentTool {
    var name: String { get }
    var description: String { get }
    // Declarative schema, simple key-value for now
    var inputSchema: [String: String] { get }
    func call(args: [String: String], policy: ToolPolicy) async throws -> String
}

public struct ToolPolicy {
    // Security gates; expand as needed
    public let allowNetwork: Bool
    public let allowFileIO: Bool
    public let allowedDomains: Set<String>
    public let allowedPaths: Set<String>
    public let maxResponseBytes: Int
    
    public init(
        allowNetwork: Bool = false,
        allowFileIO: Bool = false,
        allowedDomains: Set<String> = [],
        allowedPaths: Set<String> = [],
        maxResponseBytes: Int = 64 * 1024
    ) {
        self.allowNetwork = allowNetwork
        self.allowFileIO = allowFileIO
        self.allowedDomains = allowedDomains
        self.allowedPaths = allowedPaths
        self.maxResponseBytes = maxResponseBytes
    }
}

public actor ToolRegistry {
    private var tools: [String: AgentTool] = [:]
    
    public init() {}
    
    public func register(_ tool: AgentTool) {
        tools[tool.name] = tool
    }
    
    public func get(_ name: String) -> AgentTool? {
        tools[name]
    }
    
    public func list() -> [AgentTool] {
        Array(tools.values)
    }
}
