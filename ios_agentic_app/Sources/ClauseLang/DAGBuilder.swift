// DAG Builder: Builds execution DAG from clause dependencies
// Implements operad collapse: compose clauses → single executable KO
import Foundation

/// Builds DAG from clauses and their dependencies
public actor DAGBuilder {
    private let clauseLang: ClauseLang
    
    public init(clauseLang: ClauseLang) {
        self.clauseLang = clauseLang
    }
    
    /// Build DAG from clauses with explicit dependencies
    /// Inputs: List of clauses with their dependencies, inputs, and outputs
    public func buildDAG(
        from clauses: [ClauseInput],
        yields: [String] = [],
        inputs: [String] = []
    ) async throws -> [DAGNode] {
        var dagNodes: [DAGNode] = []
        var clauseMap: [String: ClauseInput] = [:]
        
        // Map clauses by ID
        for clauseInput in clauses {
            clauseMap[clauseInput.id] = clauseInput
        }
        
        // Build DAG nodes
        for clauseInput in clauses {
            // Parse clause if needed
            let clause: Clause
            if let parsed = clauseInput.parsedClause {
                clause = parsed
            } else {
                let ast = try await clauseLang.parse(clauseInput.rawClause)
                clause = Clause(from: ast, description: clauseInput.description)
            }
            
            // Resolve dependencies (convert clause IDs to node IDs)
            let dependencies = clauseInput.dependencies.map { depId in
                clauseMap[depId]?.nodeId ?? depId
            }
            
            // Create DAG node
            let dagNode = DAGNode(
                id: clauseInput.nodeId,
                clause: clause,
                dependencies: dependencies,
                inputs: clauseInput.inputs,
                outputs: clauseInput.outputs
            )
            
            dagNodes.append(dagNode)
        }
        
        // Validate DAG (no cycles, all dependencies exist)
        try validateDAG(dagNodes)
        
        // Topological sort to ensure correct execution order
        return topologicalSort(dagNodes)
    }
    
    /// Build DAG from yields/inputs (automatic dependency resolution)
    /// Analyzes clause outputs/inputs to infer dependencies
    public func buildDAGFromYields(
        clauses: [ClauseInput],
        yields: [String],
        inputs: [String]
    ) async throws -> [DAGNode] {
        // Analyze clause outputs to infer dependencies
        var outputMap: [String: [String]] = [:] // output -> [nodeIds that produce it]
        var inputMap: [String: [String]] = [:] // input -> [nodeIds that need it]
        
        for clauseInput in clauses {
            // Map outputs
            for output in clauseInput.outputs {
                if outputMap[output] == nil {
                    outputMap[output] = []
                }
                outputMap[output]?.append(clauseInput.nodeId)
            }
            
            // Map inputs
            for input in clauseInput.inputs {
                if inputMap[input] == nil {
                    inputMap[input] = []
                }
                inputMap[input]?.append(clauseInput.nodeId)
            }
        }
        
        // Infer dependencies: if node A needs input X, and node B produces output X, then A depends on B
        var inferredClauses = clauses
        for i in 0..<inferredClauses.count {
            var dependencies = Set<String>()
            
            for input in inferredClauses[i].inputs {
                // Find nodes that produce this input
                if let producers = outputMap[input] {
                    dependencies.formUnion(producers)
                }
            }
            
            // Remove self-dependency
            dependencies.remove(inferredClauses[i].nodeId)
            
            inferredClauses[i].dependencies = Array(dependencies)
        }
        
        // Build DAG with inferred dependencies
        return try await buildDAG(from: inferredClauses, yields: yields, inputs: inputs)
    }
    
    /// Operad Collapse: Compose multiple clauses into single executable KO
    /// Takes a DAG and collapses it into one KO with canonical execution order
    public func collapseToKO(
        dagNodes: [DAGNode],
        clauseId: String,
        type: OrchestrationType,
        role: SemanticRole,
        inputs: [String],
        yields: [String],
        loop: LoopControl? = nil,
        reflex: ReflexTriggers? = nil,
        composition: [CompositionRule]? = nil
    ) -> KernelObject {
        // Extract logic from DAG nodes
        let conditions = extractConditions(from: dagNodes)
        let actions = extractActions(from: dagNodes)
        let logic = ClauseLogic(conditions: conditions, actions: actions)
        
        // Create KO with collapsed structure
        return KernelObject(
            clauseId: clauseId,
            type: type,
            role: role,
            inputs: inputs,
            yields: yields,
            dagNodes: dagNodes,
            logic: logic,
            loop: loop,
            reflex: reflex,
            composition: composition
        )
    }
    
    // MARK: - Private Methods
    
    private func validateDAG(_ nodes: [DAGNode]) throws {
        let nodeIds = Set(nodes.map { $0.id })
        
        // Check all dependencies exist
        for node in nodes {
            for depId in node.dependencies {
                if !nodeIds.contains(depId) {
                    throw DAGBuilderError.missingDependency(nodeId: node.id, dependencyId: depId)
                }
            }
        }
        
        // Check for cycles (simple DFS)
        var visited = Set<String>()
        var recStack = Set<String>()
        
        for node in nodes {
            if !visited.contains(node.id) {
                if hasCycle(node: node, nodes: nodes, visited: &visited, recStack: &recStack) {
                    throw DAGBuilderError.cyclicDependency(nodeId: node.id)
                }
            }
        }
    }
    
    private func hasCycle(
        node: DAGNode,
        nodes: [DAGNode],
        visited: inout Set<String>,
        recStack: inout Set<String>
    ) -> Bool {
        visited.insert(node.id)
        recStack.insert(node.id)
        
        for depId in node.dependencies {
            guard let depNode = nodes.first(where: { $0.id == depId }) else { continue }
            
            if !visited.contains(depId) {
                if hasCycle(node: depNode, nodes: nodes, visited: &visited, recStack: &recStack) {
                    return true
                }
            } else if recStack.contains(depId) {
                return true // Cycle detected
            }
        }
        
        recStack.remove(node.id)
        return false
    }
    
    private func topologicalSort(_ nodes: [DAGNode]) -> [DAGNode] {
        var sorted: [DAGNode] = []
        var visited = Set<String>()
        var nodeMap: [String: DAGNode] = [:]
        
        for node in nodes {
            nodeMap[node.id] = node
        }
        
        func visit(_ node: DAGNode) {
            if visited.contains(node.id) {
                return
            }
            
            visited.insert(node.id)
            
            // Visit dependencies first
            for depId in node.dependencies {
                if let depNode = nodeMap[depId] {
                    visit(depNode)
                }
            }
            
            sorted.append(node)
        }
        
        for node in nodes {
            if !visited.contains(node.id) {
                visit(node)
            }
        }
        
        return sorted
    }
    
    private func extractConditions(from nodes: [DAGNode]) -> [LogicCondition] {
        var conditions: [LogicCondition] = []
        
        for node in nodes {
            // Extract condition from clause AST representation
            let ast = node.clause.ast
            conditions.append(LogicCondition(
                lhs: ast.condition.lhs,
                op: ast.condition.op,
                rhs: ast.condition.rhs
            ))
        }
        
        return conditions
    }
    
    private func extractActions(from nodes: [DAGNode]) -> [LogicAction] {
        var actions: [LogicAction] = []
        
        for node in nodes {
            // Extract action from clause AST representation
            let ast = node.clause.ast
            var parameters: [String: String] = [:]
            
            // Convert arguments to parameters map
            for (index, arg) in ast.action.arguments.enumerated() {
                parameters["arg\(index)"] = arg
            }
            
            actions.append(LogicAction(
                name: ast.action.function,
                parameters: parameters
            ))
        }
        
        return actions
    }
}

// MARK: - Input Types

/// Input for building DAG nodes
public struct ClauseInput {
    public let id: String
    public let nodeId: String
    public let rawClause: String
    public let parsedClause: Clause?
    public let description: String?
    public let dependencies: [String] // IDs of clauses this depends on
    public let inputs: [String] // Input identifiers
    public let outputs: [String] // Output identifiers
    
    public init(
        id: String = UUID().uuidString,
        nodeId: String? = nil,
        rawClause: String,
        parsedClause: Clause? = nil,
        description: String? = nil,
        dependencies: [String] = [],
        inputs: [String] = [],
        outputs: [String] = []
    ) {
        self.id = id
        self.nodeId = nodeId ?? id
        self.rawClause = rawClause
        self.parsedClause = parsedClause
        self.description = description
        self.dependencies = dependencies
        self.inputs = inputs
        self.outputs = outputs
    }
}

// MARK: - Errors

public enum DAGBuilderError: Error, LocalizedError {
    case missingDependency(nodeId: String, dependencyId: String)
    case cyclicDependency(nodeId: String)
    case invalidClause(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingDependency(let nodeId, let depId):
            return "Node \(nodeId) depends on missing node \(depId)"
        case .cyclicDependency(let nodeId):
            return "Cyclic dependency detected involving node \(nodeId)"
        case .invalidClause(let message):
            return "Invalid clause: \(message)"
        }
    }
}
