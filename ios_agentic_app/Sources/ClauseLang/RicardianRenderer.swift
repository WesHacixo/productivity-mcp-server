// Ricardian Renderer: Renders ClauseLang clauses in human-readable prose + machine form
// Enables user trust and debugging through legible governance
import Foundation

/// Ricardian Renderer - Renders clauses in human-readable prose alongside machine form
public struct RicardianRenderer {
    
    /// Render a clause in Ricardian format (prose + machine)
    public static func render(_ clause: Clause) -> RicardianDocument {
        let prose = renderProse(clause)
        let machine = renderMachine(clause)
        
        return RicardianDocument(
            clause: clause,
            prose: prose,
            machine: machine,
            hybrid: combineProseAndMachine(prose: prose, machine: machine)
        )
    }
    
    /// Render a Kernel Object in Ricardian format
    public static func render(_ ko: KernelObject) -> RicardianDocument {
        let prose = renderKOProse(ko)
        let machine = renderKOMachine(ko)
        
        return RicardianDocument(
            clause: nil,
            ko: ko,
            prose: prose,
            machine: machine,
            hybrid: combineProseAndMachine(prose: prose, machine: machine)
        )
    }
    
    /// Render clause prose (human-readable)
    private static func renderProse(_ clause: Clause) -> String {
        var prose = ""
        
        // Use description if available
        if let description = clause.description {
            prose += "\(description)\n\n"
        }
        
        // Render condition in prose
        let conditionProse = renderConditionProse(clause.ast.condition)
        prose += "**When:** \(conditionProse)\n\n"
        
        // Render action in prose
        let actionProse = renderActionProse(clause.ast.action)
        prose += "**Then:** \(actionProse)\n"
        
        return prose
    }
    
    /// Render condition in prose
    private static func renderConditionProse(_ condition: ConditionRepresentation) -> String {
        let lhs = humanizeVariable(condition.lhs)
        let op = humanizeOperator(condition.op)
        let rhs = humanizeValue(condition.rhs)
        
        return "\(lhs) \(op) \(rhs)"
    }
    
    /// Render action in prose
    private static func renderActionProse(_ action: ActionRepresentation) -> String {
        let function = humanizeFunction(action.function)
        
        if action.arguments.isEmpty {
            return function
        }
        
        let args = action.arguments.map { humanizeArgument($0) }.joined(separator: ", ")
        return "\(function)(\(args))"
    }
    
    /// Render KO prose
    private static func renderKOProse(_ ko: KernelObject) -> String {
        var prose = "# \(ko.clauseId)\n\n"
        prose += "**Type:** \(humanizeType(ko.type))\n"
        prose += "**Role:** \(humanizeRole(ko.role))\n\n"
        
        if !ko.inputs.isEmpty {
            prose += "**Inputs:** \(ko.inputs.joined(separator: ", "))\n\n"
        }
        
        if !ko.yields.isEmpty {
            prose += "**Outputs:** \(ko.yields.joined(separator: ", "))\n\n"
        }
        
        if let loop = ko.loop {
            prose += "**Loop Control:**\n"
            prose += "- Maximum iterations: \(loop.bounds)\n"
            if let cap = loop.entropyCap {
                prose += "- Entropy cap: \(cap)\n"
            }
            prose += "- Retry limit: \(loop.retryLimit)\n"
            if !loop.exitConditions.isEmpty {
                prose += "- Exit conditions: \(loop.exitConditions.joined(separator: ", "))\n"
            }
            prose += "\n"
        }
        
        if let reflex = ko.reflex {
            prose += "**Reflex Triggers:**\n"
            for (event, clauseId) in reflex.triggerMap {
                prose += "- \(event) → \(clauseId)\n"
            }
            prose += "\n"
        }
        
        prose += "**Execution Flow:**\n"
        for (index, node) in ko.dagNodes.enumerated() {
            prose += "\(index + 1). \(node.clause.description ?? node.clause.raw)\n"
            if !node.dependencies.isEmpty {
                prose += "   (depends on: \(node.dependencies.joined(separator: ", ")))\n"
            }
        }
        
        return prose
    }
    
    /// Render machine form (JSON/YAML)
    private static func renderMachine(_ clause: Clause) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(clause),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        
        return clause.raw
    }
    
    /// Render KO machine form
    private static func renderKOMachine(_ ko: KernelObject) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(ko),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        
        return "Unable to encode KO"
    }
    
    /// Combine prose and machine form
    private static func combineProseAndMachine(prose: String, machine: String) -> String {
        return """
        # Human-Readable (Prose)
        
        \(prose)
        
        ---
        
        # Machine-Executable (JSON)
        
        ```json
        \(machine)
        ```
        """
    }
    
    // MARK: - Humanization Helpers
    
    private static func humanizeVariable(_ variable: String) -> String {
        // Convert "user.focus_mode" to "user's focus mode"
        let parts = variable.components(separatedBy: ".")
        if parts.count == 2 {
            return "\(parts[0])'s \(parts[1].replacingOccurrences(of: "_", with: " "))"
        }
        return variable.replacingOccurrences(of: "_", with: " ")
    }
    
    private static func humanizeOperator(_ op: String) -> String {
        switch op {
        case "==": return "is"
        case "!=": return "is not"
        case ">": return "is greater than"
        case "<": return "is less than"
        case ">=": return "is greater than or equal to"
        case "<=": return "is less than or equal to"
        default: return op
        }
    }
    
    private static func humanizeValue(_ value: String) -> String {
        // Remove quotes if present
        if value.hasPrefix("\"") && value.hasSuffix("\"") {
            return String(value.dropFirst().dropLast())
        }
        return value
    }
    
    private static func humanizeFunction(_ function: String) -> String {
        return function.replacingOccurrences(of: "_", with: " ")
    }
    
    private static func humanizeArgument(_ arg: String) -> String {
        // Parse "key=value" or just "value"
        if arg.contains("=") {
            let parts = arg.components(separatedBy: "=")
            if parts.count == 2 {
                return "\(parts[0]): \(parts[1])"
            }
        }
        return arg
    }
    
    private static func humanizeType(_ type: OrchestrationType) -> String {
        switch type {
        case .orchestration: return "Orchestration"
        case .workflow: return "Workflow"
        case .scheduling: return "Scheduling"
        case .taskExecution: return "Task Execution"
        case .policyEnforcement: return "Policy Enforcement"
        case .custom(let value): return value
        }
    }
    
    private static func humanizeRole(_ role: SemanticRole) -> String {
        switch role {
        case .dataSubject: return "Data Subject"
        case .controller: return "Controller"
        case .processor: return "Processor"
        case .agent: return "AI Agent"
        case .user: return "User"
        case .system: return "System"
        }
    }
}

/// Ricardian Document - Prose + machine form
public struct RicardianDocument: Codable {
    public let clause: Clause?
    public let ko: KernelObject?
    public let prose: String
    public let machine: String
    public let hybrid: String
    
    public init(
        clause: Clause? = nil,
        ko: KernelObject? = nil,
        prose: String,
        machine: String,
        hybrid: String
    ) {
        self.clause = clause
        self.ko = ko
        self.prose = prose
        self.machine = machine
        self.hybrid = hybrid
    }
}
