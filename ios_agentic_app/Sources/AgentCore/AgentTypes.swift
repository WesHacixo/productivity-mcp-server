// Core types for agent planning, tools, and memory
import Foundation

public struct AgentMessage: Identifiable, Codable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date
    
    public enum Role: String, Codable {
        case user
        case assistant
        case system
        case tool
    }
    
    public init(role: Role, content: String, timestamp: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

public struct AgentPlanStep: Codable, Equatable {
    public let description: String
    public let toolName: String?
    public let arguments: [String: String]
    
    public init(description: String, toolName: String? = nil, arguments: [String: String] = [:]) {
        self.description = description
        self.toolName = toolName
        self.arguments = arguments
    }
}

public struct AgentPlan: Codable, Equatable {
    public let steps: [AgentPlanStep]
    
    public init(steps: [AgentPlanStep]) {
        self.steps = steps
    }
}

public enum AgentError: Error, LocalizedError {
    case cancelled
    case invalidPlan
    case toolNotFound(String)
    case toolExecution(String)
    case memoryFailure(String)
    case modelFailure(String)
    
    public var errorDescription: String? {
        switch self {
        case .cancelled: return "Operation cancelled."
        case .invalidPlan: return "Invalid plan."
        case .toolNotFound(let n): return "Tool not found: \(n)"
        case .toolExecution(let d): return "Tool execution error: \(d)"
        case .memoryFailure(let d): return "Memory error: \(d)"
        case .modelFailure(let d): return "Model error: \(d)"
        }
    }
}
