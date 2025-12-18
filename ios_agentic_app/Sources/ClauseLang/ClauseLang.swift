// ClauseLang: Minimal execution-oriented clause DSL
// Bridges human intent (prose, notes) with machine execution (validated schemas, DAG plans)
import Foundation

/// ClauseLang parser and interpreter
/// Syntax: WHEN <condition> THEN <action>
public actor ClauseLang {
    public init() {}
    
    /// Parse a ClauseLang clause string into an AST
    public func parse(_ clause: String) throws -> ClauseAST {
        // Simple PEG-style parsing
        let trimmed = clause.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Match: WHEN <condition> THEN <action>
        guard let whenRange = trimmed.range(of: "WHEN", options: .caseInsensitive) else {
            throw ClauseLangError.invalidSyntax("Missing WHEN keyword")
        }
        
        guard let thenRange = trimmed.range(of: "THEN", options: .caseInsensitive) else {
            throw ClauseLangError.invalidSyntax("Missing THEN keyword")
        }
        
        // Extract condition (between WHEN and THEN)
        let conditionStart = trimmed.index(after: whenRange.upperBound)
        let conditionEnd = thenRange.lowerBound
        let conditionStr = String(trimmed[conditionStart..<conditionEnd]).trimmingCharacters(in: .whitespaces)
        
        // Extract action (after THEN)
        let actionStart = trimmed.index(after: thenRange.upperBound)
        let actionStr = String(trimmed[actionStart...]).trimmingCharacters(in: .whitespaces)
        
        // Parse condition
        let condition = try parseCondition(conditionStr)
        
        // Parse action
        let action = try parseAction(actionStr)
        
        return ClauseAST(
            condition: condition,
            action: action,
            originalClause: clause
        )
    }
    
    /// Evaluate a clause against a context
    public func evaluate(_ clause: ClauseAST, context: ClauseContext) -> Bool {
        return evaluateCondition(clause.condition, context: context)
    }
    
    /// Execute the action if condition is true
    public func execute(_ clause: ClauseAST, context: ClauseContext) async throws -> ClauseResult {
        if evaluate(clause, context: context) {
            return try await executeAction(clause.action, context: context)
        }
        return ClauseResult(success: false, message: "Condition not met")
    }
    
    // MARK: - Private Parsing
    
    private func parseCondition(_ conditionStr: String) throws -> Condition {
        // Parse: <lhs> <op> <rhs>
        // Operators: ==, !=, >, <, >=, <=
        
        let operators = ["==", "!=", ">=", "<=", ">", "<"]
        
        for op in operators {
            if let range = conditionStr.range(of: op) {
                let lhs = String(conditionStr[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let rhs = String(conditionStr[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                
                return Condition(
                    lhs: parseValue(lhs),
                    operator: parseOperator(op),
                    rhs: parseValue(rhs)
                )
            }
        }
        
        throw ClauseLangError.invalidSyntax("Invalid condition: \(conditionStr)")
    }
    
    private func parseAction(_ actionStr: String) throws -> Action {
        // Parse action: function call or assignment
        // Examples: "normalize_fragments", "set(block.min_duration_minutes, 45)", "trigger(commit)"
        
        if actionStr.contains("(") {
            // Function call: "set(key, value)" or "trigger(event)"
            let parts = actionStr.components(separatedBy: "(")
            guard parts.count == 2 else {
                throw ClauseLangError.invalidSyntax("Invalid action: \(actionStr)")
            }
            
            let functionName = parts[0].trimmingCharacters(in: .whitespaces)
            let argsStr = parts[1].replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
            let args = argsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            return Action(
                type: .functionCall,
                function: functionName,
                arguments: args
            )
        } else {
            // Simple action name
            return Action(
                type: .simple,
                function: actionStr,
                arguments: []
            )
        }
    }
    
    private func parseValue(_ valueStr: String) -> ClauseValue {
        // Parse value: true/false, "strings", numbers, identifiers
        
        // Boolean
        if valueStr.lowercased() == "true" {
            return .boolean(true)
        }
        if valueStr.lowercased() == "false" {
            return .boolean(false)
        }
        
        // String (quoted)
        if valueStr.hasPrefix("\"") && valueStr.hasSuffix("\"") {
            let str = String(valueStr.dropFirst().dropLast())
            return .string(str)
        }
        
        // Number
        if let number = Double(valueStr) {
            return .number(number)
        }
        
        // Identifier (variable reference)
        return .identifier(valueStr)
    }
    
    private func parseOperator(_ op: String) -> Operator {
        switch op {
        case "==": return .equals
        case "!=": return .notEquals
        case ">": return .greaterThan
        case "<": return .lessThan
        case ">=": return .greaterThanOrEqual
        case "<=": return .lessThanOrEqual
        default: return .equals
        }
    }
    
    // MARK: - Evaluation
    
    private func evaluateCondition(_ condition: Condition, context: ClauseContext) -> Bool {
        let lhsValue = resolveValue(condition.lhs, context: context)
        let rhsValue = resolveValue(condition.rhs, context: context)
        
        return evaluateComparison(lhsValue, condition.operator, rhsValue)
    }
    
    private func resolveValue(_ value: ClauseValue, context: ClauseContext) -> ClauseValue {
        switch value {
        case .identifier(let name):
            // Resolve from context
            if let contextValue = context.variables[name] {
                return contextValue
            }
            return value
        default:
            return value
        }
    }
    
    private func evaluateComparison(_ lhs: ClauseValue, _ op: Operator, _ rhs: ClauseValue) -> Bool {
        switch (lhs, rhs) {
        case (.boolean(let l), .boolean(let r)):
            switch op {
            case .equals: return l == r
            case .notEquals: return l != r
            default: return false
            }
        case (.number(let l), .number(let r)):
            switch op {
            case .equals: return l == r
            case .notEquals: return l != r
            case .greaterThan: return l > r
            case .lessThan: return l < r
            case .greaterThanOrEqual: return l >= r
            case .lessThanOrEqual: return l <= r
            }
        case (.string(let l), .string(let r)):
            switch op {
            case .equals: return l == r
            case .notEquals: return l != r
            default: return false
            }
        default:
            return false
        }
    }
    
    private func executeAction(_ action: Action, context: ClauseContext) async throws -> ClauseResult {
        switch action.type {
        case .simple:
            return ClauseResult(success: true, message: "Executed: \(action.function)")
        case .functionCall:
            return try await executeFunction(action.function, arguments: action.arguments, context: context)
        }
    }
    
    private func executeFunction(_ function: String, arguments: [String], context: ClauseContext) async throws -> ClauseResult {
        // Execute built-in functions
        switch function {
        case "set":
            guard arguments.count == 2 else {
                throw ClauseLangError.invalidSyntax("set() requires 2 arguments")
            }
            // Set variable in context
            let key = arguments[0]
            let value = parseValue(arguments[1])
            context.variables[key] = value
            return ClauseResult(success: true, message: "Set \(key) = \(value)")
            
        case "trigger":
            guard arguments.count == 1 else {
                throw ClauseLangError.invalidSyntax("trigger() requires 1 argument")
            }
            let event = arguments[0]
            context.triggeredEvents.append(event)
            return ClauseResult(success: true, message: "Triggered: \(event)")
            
        default:
            return ClauseResult(success: true, message: "Executed: \(function)(\(arguments.joined(separator: ", ")))")
        }
    }
}

// MARK: - Supporting Types

public struct ClauseAST {
    public let condition: Condition
    public let action: Action
    public let originalClause: String
}

public struct Condition {
    public let lhs: ClauseValue
    public let operator: Operator
    public let rhs: ClauseValue
}

public enum Operator {
    case equals
    case notEquals
    case greaterThan
    case lessThan
    case greaterThanOrEqual
    case lessThanOrEqual
}

public enum ClauseValue: Equatable {
    case boolean(Bool)
    case number(Double)
    case string(String)
    case identifier(String)
}

public struct Action {
    public let type: ActionType
    public let function: String
    public let arguments: [String]
    
    public enum ActionType {
        case simple
        case functionCall
    }
}

public class ClauseContext {
    public var variables: [String: ClauseValue] = [:]
    public var triggeredEvents: [String] = []
    
    public init(variables: [String: ClauseValue] = [:]) {
        self.variables = variables
    }
}

public struct ClauseResult {
    public let success: Bool
    public let message: String
}

public enum ClauseLangError: Error {
    case invalidSyntax(String)
    case evaluationError(String)
}
