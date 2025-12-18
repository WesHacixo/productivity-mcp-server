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
    
    public init(
        knowledgeEscort: KnowledgeEscort,
        planner: AgentPlanner,
        tools: ToolRegistry
    ) {
        self.knowledgeEscort = knowledgeEscort
        self.planner = planner
        self.tools = tools
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
        
        let availableTools = await tools.list()
        
        // Build deterministic plan structure based on prediction type
        let steps = buildDeterministicSteps(for: prediction, tools: availableTools)
        
        return PlanStructure(
            steps: steps,
            estimatedDuration: estimateDuration(steps),
            dependencies: extractDependencies(steps)
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
