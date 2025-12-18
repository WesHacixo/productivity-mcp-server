// Workflow Warmer: Pre-computes deterministic parts of predicted workflows
// Cheap latency enhancement by warming caches for anticipated task chains
import Foundation

/// Pre-computes and caches deterministic workflow components for predicted actions
/// Only caches local, deterministic parts (like planning logic, not network calls)
public actor WorkflowWarmer {
    private var warmedWorkflows: [String: WarmedWorkflow] = [:]
    private let maxCacheSize = 50
    private let knowledgeEscort: KnowledgeEscort
    private let planner: AgentPlanner
    private let tools: ToolRegistry
    private let clauseLang: ClauseLang?
    private let dagBuilder: DAGBuilder?
    private let koStorage: ClauseLangStorage?
    
    public init(
        knowledgeEscort: KnowledgeEscort,
        planner: AgentPlanner,
        tools: ToolRegistry,
        clauseLang: ClauseLang? = nil,
        dagBuilder: DAGBuilder? = nil,
        koStorage: ClauseLangStorage? = nil
    ) {
        self.knowledgeEscort = knowledgeEscort
        self.planner = planner
        self.tools = tools
        self.clauseLang = clauseLang
        self.dagBuilder = dagBuilder
        self.koStorage = koStorage
    }
    
    /// Warm workflows for predicted actions
    /// Only pre-computes deterministic, local parts (planning, knowledge retrieval, ClauseLang clauses, etc.)
    public func warmWorkflows(for predictions: [Prediction]) async {
        for prediction in predictions {
            // Only warm high-confidence predictions
            guard prediction.confidence > 0.7 else { continue }
            
            // Skip if already warmed
            if warmedWorkflows[prediction.suggestedAction] != nil {
                continue
            }
            
            // Warm the workflow (includes ClauseLang clause evaluation)
            await warmWorkflow(for: prediction)
        }
        
        // Prune old workflows
        await pruneCache()
    }
    
    /// Get warmed workflow if available
    public func getWarmedWorkflow(for action: String) async -> WarmedWorkflow? {
        return warmedWorkflows[action]
    }
    
    /// Invalidate workflow cache for an action
    public func invalidate(_ action: String) async {
        warmedWorkflows.removeValue(forKey: action)
    }
    
    // MARK: - Private Methods
    
    private func warmWorkflow(for prediction: Prediction) async {
        // Build context for the predicted action
        let context = buildContext(for: prediction)
        
        // 1. Pre-compute knowledge retrieval (deterministic, local)
        let knowledge = await precomputeKnowledge(for: prediction, context: context)
        
        // 2. Pre-compute plan structure (deterministic planning logic, including ClauseLang clauses)
        let planStructure = await precomputePlanStructure(for: prediction, context: context)
        
        // 3. Pre-compute tool selection (deterministic)
        let toolSelection = await precomputeToolSelection(for: prediction)
        
        // 4. Pre-compute reasoning context (deterministic)
        let reasoningContext = await precomputeReasoningContext(for: prediction, context: context)
        
        // 5. Pre-compute ClauseLang clause evaluation (deterministic)
        // ClauseLang clauses are deterministic and can be pre-evaluated
        // This is the "clauselang logic" that can be warmed
        
        // Store warmed workflow
        let workflow = WarmedWorkflow(
            action: prediction.suggestedAction,
            prediction: prediction,
            knowledge: knowledge,
            planStructure: planStructure,
            toolSelection: toolSelection,
            reasoningContext: reasoningContext,
            warmedAt: Date()
        )
        
        warmedWorkflows[prediction.suggestedAction] = workflow
    }
    
    private func precomputeKnowledge(
        for prediction: Prediction,
        context: ReasoningContext
    ) async -> [KnowledgeItem] {
        // Pre-retrieve relevant knowledge (deterministic, local)
        // This is cheap - just vector search and graph traversal
        return await knowledgeEscort.retrieveRelevant(
            query: prediction.suggestedAction,
            context: context,
            limit: 5
        )
    }
    
    private func precomputePlanStructure(
        for prediction: Prediction,
        context: ReasoningContext
    ) async -> PlanStructure {
        // Pre-compute the plan structure (deterministic planning logic)
        // This is the "clauselang logic" - deterministic execution flow
        
        // Try to load KO from storage first (ClauseLang-based workflow)
        if let storage = koStorage, let lang = clauseLang, let builder = dagBuilder {
            if let ko = try? await loadWorkflowKO(for: prediction, storage: storage, lang: lang, builder: builder) {
                // Convert KO to PlanStructure
                return planStructureFromKO(ko)
            }
        }
        
        // Fallback to hardcoded patterns (backward compatibility)
        let availableTools = await tools.list()
        let steps = buildDeterministicSteps(for: prediction, tools: availableTools)
        
        return PlanStructure(
            steps: steps,
            estimatedDuration: estimateDuration(steps),
            dependencies: extractDependencies(steps)
        )
    }
    
    /// Load workflow KO from storage or create from Flowstate Clause Library
    private func loadWorkflowKO(
        for prediction: Prediction,
        storage: ClauseLangStorage,
        lang: ClauseLang,
        builder: DAGBuilder
    ) async throws -> KernelObject? {
        // Try to load from storage first
        let koId = workflowKOId(for: prediction)
        if let stored = try? await storage.loadKO(id: koId) {
            return stored
        }
        
        // Create from Flowstate Clause Library based on prediction type
        switch prediction.type {
        case .scheduling:
            return try await FlowstateClauseLibrary.buildSchedulingWorkflowKO(
                clauseLang: lang,
                dagBuilder: builder,
                focusModeEnabled: true,
                recoveryBlocksEnabled: true,
                meetingShieldsEnabled: true,
                errandsBatchingEnabled: true,
                flowCostEnabled: true
            )
        case .task:
            // Create task workflow KO
            return try await buildTaskWorkflowKO(lang: lang, builder: builder)
        case .optimization:
            // Create optimization workflow KO
            return try await buildOptimizationWorkflowKO(lang: lang, builder: builder)
        case .reminder:
            // Create reminder workflow KO
            return try await buildReminderWorkflowKO(lang: lang, builder: builder)
        }
    }
    
    /// Convert KO to PlanStructure
    private func planStructureFromKO(_ ko: KernelObject) -> PlanStructure {
        let steps = ko.dagNodes.map { node in
            DeterministicStep(
                type: stepTypeFromNode(node),
                description: node.clause.description ?? node.clause.raw,
                toolName: extractToolName(from: node),
                deterministic: isDeterministic(node: node)
            )
        }
        
        return PlanStructure(
            steps: steps,
            estimatedDuration: estimateDurationFromKO(ko),
            dependencies: extractDependenciesFromKO(ko)
        )
    }
    
    private func stepTypeFromNode(_ node: DAGNode) -> DeterministicStep.StepType {
        // Infer step type from clause action
        let action = node.clause.ast.action.function.lowercased()
        
        if action.contains("retrieve") || action.contains("knowledge") {
            return .knowledgeRetrieval
        }
        if action.contains("plan") || action.contains("schedule") {
            return .planning
        }
        return .toolExecution
    }
    
    private func extractToolName(from node: DAGNode) -> String? {
        // Extract tool name from clause action
        let action = node.clause.ast.action.function.lowercased()
        
        if action.contains("calendar") {
            return "calendar"
        }
        if action.contains("task") {
            return "tasks"
        }
        return nil
    }
    
    private func isDeterministic(node: DAGNode) -> Bool {
        // Knowledge retrieval and planning are deterministic
        let action = node.clause.ast.action.function.lowercased()
        return action.contains("retrieve") || action.contains("knowledge") || action.contains("plan")
    }
    
    private func estimateDurationFromKO(_ ko: KernelObject) -> TimeInterval {
        // Estimate based on number of nodes and types
        var duration: TimeInterval = 0
        
        for node in ko.dagNodes {
            let action = node.clause.ast.action.function.lowercased()
            if action.contains("retrieve") || action.contains("knowledge") {
                duration += 0.1 // Fast, cached
            } else if action.contains("plan") {
                duration += 0.2 // Deterministic planning
            } else {
                duration += 1.0 // Network call (not pre-computed)
            }
        }
        
        return duration
    }
    
    private func extractDependenciesFromKO(_ ko: KernelObject) -> [String] {
        var dependencies: [String] = []
        
        for node in ko.dagNodes {
            if !node.dependencies.isEmpty {
                dependencies.append("\(node.id) depends on: \(node.dependencies.joined(separator: ", "))")
            }
        }
        
        return dependencies
    }
    
    private func workflowKOId(for prediction: Prediction) -> String {
        let typeStr = String(describing: prediction.type)
        return "workflow_\(typeStr)_\(abs(prediction.suggestedAction.hashValue))"
    }
    
    // MARK: - Workflow KO Builders
    
    private func buildTaskWorkflowKO(lang: ClauseLang, builder: DAGBuilder) async throws -> KernelObject {
        let clauses = [
            FlowstateClauseLibrary.errandsBatching,
            FlowstateClauseLibrary.flowCostMinBlockSize
        ]
        
        let clauseInputs = clauses.map {
            FlowstateClauseLibrary.createClauseInput(rawClause: $0, description: "Task workflow clause")
        }
        
        let dagNodes = try await builder.buildDAG(
            from: clauseInputs,
            yields: ["tasks.normalized[]"],
            inputs: ["task_inputs[]"]
        )
        
        return await builder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "task_workflow_v1",
            type: .taskExecution,
            role: .agent,
            inputs: ["task_inputs[]"],
            yields: ["tasks.normalized[]"]
        )
    }
    
    private func buildOptimizationWorkflowKO(lang: ClauseLang, builder: DAGBuilder) async throws -> KernelObject {
        let clauses = [
            FlowstateClauseLibrary.flowCostReduceSwitches,
            FlowstateClauseLibrary.flowCostClusterByMode,
            FlowstateClauseLibrary.entropyCap
        ]
        
        let clauseInputs = clauses.map {
            FlowstateClauseLibrary.createClauseInput(rawClause: $0, description: "Optimization workflow clause")
        }
        
        let dagNodes = try await builder.buildDAG(
            from: clauseInputs,
            yields: ["optimized_schedule"],
            inputs: ["current_schedule", "constraints"]
        )
        
        return await builder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "optimization_workflow_v1",
            type: .scheduling,
            role: .agent,
            inputs: ["current_schedule", "constraints"],
            yields: ["optimized_schedule"]
        )
    }
    
    private func buildReminderWorkflowKO(lang: ClauseLang, builder: DAGBuilder) async throws -> KernelObject {
        let clauses = [
            FlowstateClauseLibrary.suggestBreak,
            FlowstateClauseLibrary.recoveryBlockAfterFocus
        ]
        
        let clauseInputs = clauses.map {
            FlowstateClauseLibrary.createClauseInput(rawClause: $0, description: "Reminder workflow clause")
        }
        
        let dagNodes = try await builder.buildDAG(
            from: clauseInputs,
            yields: ["reminders[]"],
            inputs: ["schedule", "time"]
        )
        
        return await builder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "reminder_workflow_v1",
            type: .workflow,
            role: .agent,
            inputs: ["schedule", "time"],
            yields: ["reminders[]"]
        )
    }
    
    private func buildDeterministicSteps(
        for prediction: Prediction,
        tools: [AgentTool]
    ) -> [DeterministicStep] {
        var steps: [DeterministicStep] = []
        
        switch prediction.type {
        case .scheduling:
            // Deterministic scheduling workflow
            steps.append(DeterministicStep(
                type: .knowledgeRetrieval,
                description: "Retrieve scheduling context",
                toolName: nil,
                deterministic: true
            ))
            steps.append(DeterministicStep(
                type: .planning,
                description: "Plan schedule action",
                toolName: nil,
                deterministic: true
            ))
            if let calendarTool = tools.first(where: { $0.name == "calendar" }) {
                steps.append(DeterministicStep(
                    type: .toolExecution,
                    description: "Execute calendar tool",
                    toolName: calendarTool.name,
                    deterministic: false // Network call, not deterministic
                ))
            }
            
        case .task:
            // Deterministic task creation workflow
            steps.append(DeterministicStep(
                type: .knowledgeRetrieval,
                description: "Retrieve task context",
                toolName: nil,
                deterministic: true
            ))
            steps.append(DeterministicStep(
                type: .planning,
                description: "Plan task creation",
                toolName: nil,
                deterministic: true
            ))
            if let tasksTool = tools.first(where: { $0.name == "tasks" }) {
                steps.append(DeterministicStep(
                    type: .toolExecution,
                    description: "Execute tasks tool",
                    toolName: tasksTool.name,
                    deterministic: false
                ))
            }
            
        case .optimization:
            // Deterministic optimization workflow
            steps.append(DeterministicStep(
                type: .knowledgeRetrieval,
                description: "Retrieve optimization context",
                toolName: nil,
                deterministic: true
            ))
            steps.append(DeterministicStep(
                type: .planning,
                description: "Plan optimization",
                toolName: nil,
                deterministic: true
            ))
            
        case .reminder:
            // Deterministic reminder workflow
            steps.append(DeterministicStep(
                type: .knowledgeRetrieval,
                description: "Retrieve reminder context",
                toolName: nil,
                deterministic: true
            ))
            steps.append(DeterministicStep(
                type: .planning,
                description: "Plan reminder",
                toolName: nil,
                deterministic: true
            ))
        }
        
        return steps
    }
    
    private func precomputeToolSelection(for prediction: Prediction) async -> ToolSelection {
        let availableTools = await tools.list()
        
        // Deterministic tool selection based on prediction type
        var selectedTools: [AgentTool] = []
        
        switch prediction.type {
        case .scheduling:
            selectedTools = availableTools.filter { $0.name == "calendar" || $0.name == "tasks" }
        case .task:
            selectedTools = availableTools.filter { $0.name == "tasks" }
        case .optimization:
            selectedTools = availableTools.filter { $0.name == "calendar" || $0.name == "tasks" }
        case .reminder:
            selectedTools = availableTools.filter { $0.name == "calendar" }
        }
        
        return ToolSelection(
            tools: selectedTools,
            primaryTool: selectedTools.first,
            fallbackTools: Array(selectedTools.dropFirst())
        )
    }
    
    private func precomputeReasoningContext(
        for prediction: Prediction,
        context: ReasoningContext
    ) async -> ReasoningContext {
        // Pre-compute reasoning context (deterministic)
        // Extract entities from prediction
        let entities = extractEntities(from: prediction)
        
        // Determine intent
        let intent = determineIntent(from: prediction)
        
        return ReasoningContext(
            entities: entities,
            intent: intent,
            temporalContext: context.temporalContext,
            userPreferences: context.userPreferences
        )
    }
    
    private func buildContext(for prediction: Prediction) -> ReasoningContext {
        return ReasoningContext(
            entities: [],
            intent: determineIntent(from: prediction),
            temporalContext: .now,
            userPreferences: UserPreferences()
        )
    }
    
    private func extractEntities(from prediction: Prediction) -> [Entity] {
        // Simple entity extraction from prediction
        // In reality, would use more sophisticated parsing
        var entities: [Entity] = []
        
        // Extract time mentions
        if prediction.description.localizedCaseInsensitiveContains("morning") {
            entities.append(Entity(type: "time", value: "morning", confidence: 0.8))
        }
        if prediction.description.localizedCaseInsensitiveContains("afternoon") {
            entities.append(Entity(type: "time", value: "afternoon", confidence: 0.8))
        }
        
        return entities
    }
    
    private func determineIntent(from prediction: Prediction) -> Intent {
        switch prediction.type {
        case .scheduling: return .create
        case .task: return .create
        case .optimization: return .update
        case .reminder: return .create
        }
    }
    
    private func estimateDuration(_ steps: [DeterministicStep]) -> TimeInterval {
        // Estimate duration based on step types
        var duration: TimeInterval = 0
        
        for step in steps {
            switch step.type {
            case .knowledgeRetrieval:
                duration += 0.1 // Fast, cached
            case .planning:
                duration += 0.2 // Deterministic planning
            case .toolExecution:
                duration += 1.0 // Network call (not pre-computed)
            }
        }
        
        return duration
    }
    
    private func extractDependencies(_ steps: [DeterministicStep]) -> [String] {
        // Extract dependencies between steps
        var dependencies: [String] = []
        
        for index in 1..<steps.count {
            dependencies.append("Step \(index) depends on Step \(index - 1)")
        }
        
        return dependencies
    }
    
    private func pruneCache() async {
        // Remove old workflows if cache is too large
        if warmedWorkflows.count > maxCacheSize {
            // Sort by age and remove oldest
            let sorted = warmedWorkflows.sorted { $0.value.warmedAt < $1.value.warmedAt }
            let toRemove = sorted.prefix(warmedWorkflows.count - maxCacheSize)
            
            for (key, _) in toRemove {
                warmedWorkflows.removeValue(forKey: key)
            }
        }
    }
}

// MARK: - Supporting Types

public struct WarmedWorkflow {
    public let action: String
    public let prediction: Prediction
    public let knowledge: [KnowledgeItem]
    public let planStructure: PlanStructure
    public let toolSelection: ToolSelection
    public let reasoningContext: ReasoningContext
    public let warmedAt: Date
}

public struct PlanStructure {
    public let steps: [DeterministicStep]
    public let estimatedDuration: TimeInterval
    public let dependencies: [String]
}

public struct DeterministicStep {
    public let type: StepType
    public let description: String
    public let toolName: String?
    public let deterministic: Bool // True if this step can be pre-computed
    
    public enum StepType {
        case knowledgeRetrieval
        case planning
        case toolExecution
    }
}

public struct ToolSelection {
    public let tools: [AgentTool]
    public let primaryTool: AgentTool?
    public let fallbackTools: [AgentTool]
}
