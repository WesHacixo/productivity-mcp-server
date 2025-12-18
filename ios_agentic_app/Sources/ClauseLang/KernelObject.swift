// Kernel Object (KO): The executable artifact after parsing + validation + composition
// Represents a composed ClauseLang workflow ready for orchestration
import Foundation

// MARK: - Semantic Roles (if not defined elsewhere)

public enum SemanticRole: String, Codable {
    case dataSubject = "data_subject"
    case controller = "controller"
    case processor = "processor"
    case agent = "agent"
    case user = "user"
    case system = "system"
}

/// Kernel Object - The smallest executable artifact the runtime needs after parsing + validation + composition
/// This is "what the orchestrator actually runs"
public struct KernelObject: Codable, Equatable, Identifiable {
    public let id: String
    public let clauseId: String
    public let type: OrchestrationType
    public let role: SemanticRole
    public let inputs: [String]
    public let yields: [String]
    public let dagNodes: [DAGNode]
    public let logic: ClauseLogic
    public let loop: LoopControl?
    public let reflex: ReflexTriggers?
    public let composition: [CompositionRule]?
    public let metadata: KernelMetadata
    
    public init(
        id: String = UUID().uuidString,
        clauseId: String,
        type: OrchestrationType,
        role: SemanticRole,
        inputs: [String],
        yields: [String],
        dagNodes: [DAGNode],
        logic: ClauseLogic,
        loop: LoopControl? = nil,
        reflex: ReflexTriggers? = nil,
        composition: [CompositionRule]? = nil,
        metadata: KernelMetadata = KernelMetadata()
    ) {
        self.id = id
        self.clauseId = clauseId
        self.type = type
        self.role = role
        self.inputs = inputs
        self.yields = yields
        self.dagNodes = dagNodes
        self.logic = logic
        self.loop = loop
        self.reflex = reflex
        self.composition = composition
        self.metadata = metadata
    }
}

/// Orchestration type for Kernel Objects
public enum OrchestrationType: String, Codable {
    case orchestration
    case workflow
    case scheduling
    case taskExecution
    case policyEnforcement
    case custom(String)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "orchestration": self = .orchestration
        case "workflow": self = .workflow
        case "scheduling": self = .scheduling
        case "taskExecution": self = .taskExecution
        case "policyEnforcement": self = .policyEnforcement
        default: self = .custom(rawValue)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    public var rawValue: String {
        switch self {
        case .orchestration: return "orchestration"
        case .workflow: return "workflow"
        case .scheduling: return "scheduling"
        case .taskExecution: return "taskExecution"
        case .policyEnforcement: return "policyEnforcement"
        case .custom(let value): return value
        }
    }
}

/// Clause - Wraps ClauseAST for use in Kernel Objects
public struct Clause: Codable, Equatable {
    public let id: String
    public let raw: String // Original ClauseLang syntax
    public let ast: ClauseASTRepresentation // Serializable representation
    public let description: String?
    
    public init(
        id: String = UUID().uuidString,
        raw: String,
        ast: ClauseASTRepresentation,
        description: String? = nil
    ) {
        self.id = id
        self.raw = raw
        self.ast = ast
        self.description = description
    }
    
    /// Create from ClauseAST
    public init(from ast: ClauseAST, description: String? = nil) {
        self.id = UUID().uuidString
        self.raw = ast.originalClause
        self.ast = ClauseASTRepresentation(from: ast)
        self.description = description
    }
}

/// Serializable representation of ClauseAST
public struct ClauseASTRepresentation: Codable, Equatable {
    public let condition: ConditionRepresentation
    public let action: ActionRepresentation
    public let originalClause: String
    
    public init(from ast: ClauseAST) {
        self.condition = ConditionRepresentation(from: ast.condition)
        self.action = ActionRepresentation(from: ast.action)
        self.originalClause = ast.originalClause
    }
    
    public init(condition: ConditionRepresentation, action: ActionRepresentation, originalClause: String) {
        self.condition = condition
        self.action = action
        self.originalClause = originalClause
    }
}

/// Serializable representation of Condition
public struct ConditionRepresentation: Codable, Equatable {
    public let lhs: String
    public let op: String
    public let rhs: String
    
    public init(from condition: Condition) {
        self.lhs = stringifyValue(condition.lhs)
        self.op = stringifyOperator(condition.operator)
        self.rhs = stringifyValue(condition.rhs)
    }
    
    private func stringifyValue(_ value: ClauseValue) -> String {
        switch value {
        case .boolean(let b): return String(b)
        case .number(let n): return String(n)
        case .string(let s): return "\"\(s)\""
        case .identifier(let i): return i
        }
    }
    
    private func stringifyOperator(_ op: Operator) -> String {
        switch op {
        case .equals: return "=="
        case .notEquals: return "!="
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .greaterThanOrEqual: return ">="
        case .lessThanOrEqual: return "<="
        }
    }
}

/// Serializable representation of Action
public struct ActionRepresentation: Codable, Equatable {
    public let type: String
    public let function: String
    public let arguments: [String]
    
    public init(from action: Action) {
        self.type = action.type == .simple ? "simple" : "functionCall"
        self.function = action.function
        self.arguments = action.arguments
    }
}

/// DAG Node - Represents a node in the execution DAG
public struct DAGNode: Codable, Equatable, Identifiable {
    public let id: String
    public let clause: Clause
    public let dependencies: [String] // IDs of nodes this depends on
    public let inputs: [String] // Input identifiers
    public let outputs: [String] // Output identifiers
    
    public init(
        id: String,
        clause: Clause,
        dependencies: [String] = [],
        inputs: [String] = [],
        outputs: [String] = []
    ) {
        self.id = id
        self.clause = clause
        self.dependencies = dependencies
        self.inputs = inputs
        self.outputs = outputs
    }
}

/// Clause Logic - Conditions and actions for a KO
public struct ClauseLogic: Codable, Equatable {
    public let conditions: [LogicCondition]
    public let actions: [LogicAction]
    
    public init(
        conditions: [LogicCondition] = [],
        actions: [LogicAction] = []
    ) {
        self.conditions = conditions
        self.actions = actions
    }
}

/// Logic Condition - Left-hand side, operator, right-hand side
public struct LogicCondition: Codable, Equatable {
    public let lhs: String // Left-hand side (e.g., "user.focus_mode")
    public let op: String // Operator as string (==, !=, >, <, >=, <=)
    public let rhs: String // Right-hand side value as string
    
    public init(lhs: String, op: String, rhs: String) {
        self.lhs = lhs
        self.op = op
        self.rhs = rhs
    }
}

/// Logic Action - Executable action
public struct LogicAction: Codable, Equatable {
    public let name: String
    public let parameters: [String: String] // Parameters as string values
    
    public init(name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

/// Loop Control - Bounds, entropy caps, retry limits
public struct LoopControl: Codable, Equatable {
    public let bounds: Int
    public let entropyCap: Double?
    public let retryLimit: Int
    public let retryScope: String
    public let exitConditions: [String]
    
    public init(
        bounds: Int,
        entropyCap: Double? = nil,
        retryLimit: Int = 2,
        retryScope: String = "DAG-local",
        exitConditions: [String] = []
    ) {
        self.bounds = bounds
        self.entropyCap = entropyCap
        self.retryLimit = retryLimit
        self.retryScope = retryScope
        self.exitConditions = exitConditions
    }
}

/// Reflex Triggers - Event-driven clause activation
public struct ReflexTriggers: Codable, Equatable {
    public let triggerMap: [String: String] // event_name -> clause_id
    public let entropyHint: Double?
    public let kernel: String?
    
    public init(
        triggerMap: [String: String],
        entropyHint: Double? = nil,
        kernel: String? = nil
    ) {
        self.triggerMap = triggerMap
        self.entropyHint = entropyHint
        self.kernel = kernel
    }
}

/// Composition Rule - Clause insertion/substitution
public struct CompositionRule: Codable, Equatable {
    public let insert: String // "nodeA into nodeB at index i"
    public let triggeredBy: String // Event that triggers this composition
    
    public init(insert: String, triggeredBy: String) {
        self.insert = insert
        self.triggeredBy = triggeredBy
    }
}

/// Kernel Metadata
public struct KernelMetadata: Codable, Equatable {
    public let version: String
    public let validated: Bool
    public let siglereChecksum: String?
    public let createdAt: Date?
    public let updatedAt: Date?
    
    public init(
        version: String = "vΣ.6.0",
        validated: Bool = false,
        siglereChecksum: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.version = version
        self.validated = validated
        self.siglereChecksum = siglereChecksum
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }
}

// MARK: - KO Execution State

/// Execution state for a running Kernel Object
public struct KOExecutionState: Codable {
    public let koId: String
    public let currentNodeId: String?
    public let completedNodes: Set<String>
    public let iteration: Int
    public let entropy: Double
    public let retryCount: Int
    public let events: [KOEvent]
    public let startedAt: Date
    public let lastUpdatedAt: Date
    
    public init(
        koId: String,
        currentNodeId: String? = nil,
        completedNodes: Set<String> = [],
        iteration: Int = 0,
        entropy: Double = 0.0,
        retryCount: Int = 0,
        events: [KOEvent] = [],
        startedAt: Date = Date(),
        lastUpdatedAt: Date = Date()
    ) {
        self.koId = koId
        self.currentNodeId = currentNodeId
        self.completedNodes = completedNodes
        self.iteration = iteration
        self.entropy = entropy
        self.retryCount = retryCount
        self.events = events
        self.startedAt = startedAt
        self.lastUpdatedAt = lastUpdatedAt
    }
}

/// Event emitted during KO execution
public struct KOEvent: Codable, Identifiable {
    public let id: String
    public let type: EventType
    public let nodeId: String?
    public let message: String
    public let timestamp: Date
    public let data: [String: String]?
    
    public enum EventType: String, Codable {
        case nodeStarted
        case nodeCompleted
        case nodeFailed
        case reflexTriggered
        case loopIteration
        case entropyCapReached
        case exitConditionMet
        case custom(String)
    }
    
    public init(
        id: String = UUID().uuidString,
        type: EventType,
        nodeId: String? = nil,
        message: String,
        timestamp: Date = Date(),
        data: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.nodeId = nodeId
        self.message = message
        self.timestamp = timestamp
        self.data = data
    }
}

// MARK: - KO Execution Result

/// Result of executing a Kernel Object
public struct KOExecutionResult: Codable {
    public let koId: String
    public let success: Bool
    public let outputs: [String: AnyCodable]
    public let executionState: KOExecutionState
    public let error: String?
    public let duration: TimeInterval
    
    public init(
        koId: String,
        success: Bool,
        outputs: [String: AnyCodable] = [:],
        executionState: KOExecutionState,
        error: String? = nil,
        duration: TimeInterval
    ) {
        self.koId = koId
        self.success = success
        self.outputs = outputs
        self.executionState = executionState
        self.error = error
        self.duration = duration
    }
}

// MARK: - AnyCodable Helper

/// Type-erased Codable for dynamic values in execution results
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
