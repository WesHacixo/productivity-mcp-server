// Enterprise-grade reasoning engine with self-reflection and knowledge escort capabilities
import Foundation

/// Reasoning engine that orchestrates planning, execution, reflection, and knowledge integration
public actor ReasoningEngine {
    private let planner: AgentPlanner
    private let knowledgeBase: KnowledgeEscort
    private let tools: ToolRegistry
    private let memory: AgentMemory
    
    // Reasoning state
    private var reasoningTrace: [ReasoningStep] = []
    private var currentContext: ReasoningContext?
    
    private let mlxLLM: MLXLLM?
    private let workflowWarmer: WorkflowWarmer?
    private let clauseLangPolicy: ClauseLangPolicy?
    
    public init(
        planner: AgentPlanner,
        knowledgeBase: KnowledgeEscort,
        tools: ToolRegistry,
        memory: AgentMemory,
        mlxLLM: MLXLLM? = nil,
        workflowWarmer: WorkflowWarmer? = nil,
        clauseLangPolicy: ClauseLangPolicy? = nil
    ) {
        self.planner = planner
        self.knowledgeBase = knowledgeBase
        self.tools = tools
        self.memory = memory
        self.mlxLLM = mlxLLM
        self.workflowWarmer = workflowWarmer
        self.clauseLangPolicy = clauseLangPolicy
    }
    
    /// Main reasoning loop: understand → plan → execute → reflect → integrate knowledge
    /// Uses warmed workflows when available for latency reduction
    public func reason(about userInput: String, maxIterations: Int = 5) async throws -> ReasoningResult {
        let trace = ReasoningTrace(id: UUID(), startedAt: Date())
        var iterations = 0
        var currentPlan: AgentPlan?
        var accumulatedResults: [AgentMessage] = []
        
        // Check for warmed workflow (latency optimization)
        var warmedWorkflow: WarmedWorkflow? = nil
        if let warmer = workflowWarmer {
            warmedWorkflow = await warmer.getWarmedWorkflow(for: userInput)
        }
        
        // Step 1: Understand intent with knowledge context
        let understanding = try await understandIntent(userInput, trace: trace)
        
        // Step 2: Retrieve relevant knowledge (use warmed if available)
        let relevantKnowledge: [KnowledgeItem]
        if let warmed = warmedWorkflow {
            // Use pre-computed knowledge (fast!)
            relevantKnowledge = warmed.knowledge
        } else {
            // Normal retrieval
            relevantKnowledge = await knowledgeBase.retrieveRelevant(
                query: userInput,
                context: understanding.context,
                limit: 5
            )
        }
        
        // Step 3: Plan with knowledge-informed context (use warmed if available)
        let availableTools = await tools.list()
        if let warmed = warmedWorkflow {
            // Use pre-computed plan structure (fast!)
            currentPlan = await buildPlanFromWarmedWorkflow(warmed, userInput: userInput, tools: availableTools)
        } else {
            // Normal planning
            currentPlan = await planner.plan(
                for: userInput,
                availableTools: availableTools,
                knowledgeContext: relevantKnowledge
            )
        }
        
        // Step 4: Execute plan with reflection loop
        while iterations < maxIterations {
            iterations += 1
            
            guard let plan = currentPlan else { break }
            
            // Execute plan step
            let executionResult = try await executePlan(plan, trace: trace)
            accumulatedResults.append(contentsOf: executionResult.messages)
            
            // Reflect on execution
            let reflection = try await reflectOnExecution(
                originalPlan: plan,
                executionResult: executionResult,
                knowledgeContext: relevantKnowledge
            )
            
            // If reflection indicates success or terminal state, break
            if reflection.shouldTerminate {
                trace.addStep(.reflection(reflection))
                break
            }
            
            // If reflection suggests plan revision, update plan
            if let revisedPlan = reflection.revisedPlan {
                currentPlan = revisedPlan
                trace.addStep(.planRevision(revisedPlan))
            } else {
                break
            }
        }
        
        // Step 5: Integrate new knowledge
        await knowledgeBase.integrate(
            query: userInput,
            results: accumulatedResults,
            reasoningTrace: trace
        )
        
        trace.completedAt = Date()
        
        return ReasoningResult(
            trace: trace,
            messages: accumulatedResults,
            knowledgeIntegrated: true
        )
    }
    
    /// Understand user intent with context extraction
    private func understandIntent(_ input: String, trace: ReasoningTrace) async throws -> Understanding {
        // Extract entities, intent, and context
        let entities = extractEntities(from: input)
        let intent = classifyIntent(from: input)
        let context = ReasoningContext(
            entities: entities,
            intent: intent,
            temporalContext: .now,
            userPreferences: await retrieveUserPreferences()
        )
        
        trace.addStep(.understanding(context))
        
        return Understanding(
            intent: intent,
            entities: entities,
            context: context,
            confidence: 0.85 // TODO: Use MLX for confidence scoring
        )
    }
    
    /// Execute plan with error recovery
    private func executePlan(_ plan: AgentPlan, trace: ReasoningTrace) async throws -> ExecutionResult {
        var messages: [AgentMessage] = []
        var errors: [AgentError] = []
        
        for step in plan.steps {
            trace.addStep(.execution(step))
            
            if let toolName = step.toolName, let tool = await tools.get(toolName) {
                do {
                    // Evaluate with ClauseLang policy first
                    let policyEvaluation = await evaluateToolActionWithPolicy(
                        toolName: toolName,
                        arguments: step.arguments,
                        context: currentContext ?? ReasoningContext(
                            entities: [],
                            intent: .general,
                            temporalContext: .now,
                            userPreferences: UserPreferences()
                        )
                    )
                    
                    if !policyEvaluation.isAllowed {
                        let reason = policyEvaluation.isAllowed ? "" : {
                            if case .denied(let r) = policyEvaluation { return r } else { return "Policy violation" }
                        }()
                        let errorMsg = AgentMessage(
                            role: .system,
                            content: "Tool '\(toolName)' denied by policy: \(reason)",
                            timestamp: Date()
                        )
                        messages.append(errorMsg)
                        errors.append(.toolExecution("Policy violation: \(reason)"))
                        continue
                    }
                    
                    let policy = await getPolicyForTool(toolName)
                    let result = try await tool.call(args: step.arguments, policy: policy)
                    let toolMsg = AgentMessage(role: .tool, content: "[\(toolName)] \(result)", timestamp: Date())
                    messages.append(toolMsg)
                    await memory.append(toolMsg)
                } catch {
                    errors.append(error as? AgentError ?? .toolExecution(error.localizedDescription))
                    // Attempt recovery
                    if let recovery = await attemptRecovery(error: error, step: step) {
                        messages.append(recovery)
                    }
                }
            } else {
                // Non-tool step - generate response
                let response = await generateResponse(for: step)
                let assistantMsg = AgentMessage(role: .assistant, content: response, timestamp: Date())
                messages.append(assistantMsg)
                await memory.append(assistantMsg)
            }
        }
        
        return ExecutionResult(messages: messages, errors: errors)
    }
    
    /// Reflect on execution and determine if plan needs revision
    private func reflectOnExecution(
        originalPlan: AgentPlan,
        executionResult: ExecutionResult,
        knowledgeContext: [KnowledgeItem]
    ) async throws -> Reflection {
        // Use MLX for reflection if available
        if let mlx = mlxLLM {
            do {
                let context = SchedulingContext(
                    currentTime: Date(),
                    todayEvents: [],
                    tomorrowEvents: [],
                    upcomingEvents: [],
                    taskBacklog: [],
                    availableSlots: [],
                    userPreferences: UserSchedulingPreferences(
                        preferredWorkHours: (start: 9, end: 17),
                        bufferTime: 15 * 60,
                        autoSchedule: true
                    )
                )
                return try await mlx.reflect(
                    originalPlan: originalPlan,
                    executionResults: executionResult.messages,
                    schedulingContext: context
                )
            } catch {
                // Fallback to heuristic
            }
        }
        // Analyze execution results
        let hasErrors = !executionResult.errors.isEmpty
        let successRate = Double(executionResult.messages.count - executionResult.errors.count) / Double(originalPlan.steps.count)
        
        // Check if goals were achieved
        let goalsAchieved = successRate > 0.8 && !hasErrors
        
        // Determine if we should revise plan
        var revisedPlan: AgentPlan? = nil
        var shouldTerminate = goalsAchieved || executionResult.errors.count >= originalPlan.steps.count
        
        if hasErrors && !shouldTerminate {
            // Attempt to create revised plan
            revisedPlan = await createRevisedPlan(
                originalPlan: originalPlan,
                errors: executionResult.errors,
                knowledgeContext: knowledgeContext
            )
        }
        
        return Reflection(
            goalsAchieved: goalsAchieved,
            successRate: successRate,
            errors: executionResult.errors,
            shouldTerminate: shouldTerminate,
            revisedPlan: revisedPlan,
            insights: extractInsights(from: executionResult)
        )
    }
    
    // MARK: - Helper Methods
    
    private func extractEntities(from input: String) -> [Entity] {
        // TODO: Use MLX NER model
        // For now, simple keyword extraction
        return []
    }
    
    private func classifyIntent(from input: String) -> Intent {
        let lower = input.lowercased()
        if lower.contains("create") || lower.contains("add") {
            return .create
        } else if lower.contains("find") || lower.contains("search") || lower.contains("get") {
            return .retrieve
        } else if lower.contains("update") || lower.contains("modify") || lower.contains("change") {
            return .update
        } else if lower.contains("delete") || lower.contains("remove") {
            return .delete
        } else if lower.contains("analyze") || lower.contains("understand") {
            return .analyze
        }
        return .general
    }
    
    private func retrieveUserPreferences() async -> UserPreferences {
        // TODO: Load from persistent storage
        return UserPreferences()
    }
    
    private func getPolicyForTool(_ toolName: String) async -> ToolPolicy {
        // Use ClauseLang policy if available, otherwise fallback to default
        if let clausePolicy = clauseLangPolicy {
            return clausePolicy.basePolicy
        }
        
        // TODO: Load from settings or user preferences
        return ToolPolicy(
            allowNetwork: true,
            allowFileIO: true,
            allowedDomains: ["api.github.com", "example.com"],
            allowedPaths: ["Documents", "Library"],
            maxResponseBytes: 256 * 1024
        )
    }
    
    /// Evaluate tool action with ClauseLang policy
    private func evaluateToolActionWithPolicy(
        toolName: String,
        arguments: [String: String],
        context: ReasoningContext
    ) async -> PolicyEvaluationResult {
        // If no ClauseLang policy, allow by default (base policy already checked)
        guard let clausePolicy = clauseLangPolicy else {
            return .allowed
        }
        
        // Create evaluation context
        let evalContext = PolicyEvaluationContext(
            toolName: toolName,
            toolArguments: arguments,
            userRole: .user, // TODO: Get from context
            dataTypes: [], // TODO: Extract from arguments
            jurisdiction: nil, // TODO: Get from policy
            customVariables: extractCustomVariables(from: context)
        )
        
        // Evaluate with ClauseLang policy
        return clausePolicy.evaluateToolAction(
            toolName: toolName,
            arguments: arguments,
            context: evalContext
        )
    }
    
    private func extractCustomVariables(from context: ReasoningContext) -> [String: ConditionValue] {
        var variables: [String: ConditionValue] = [:]
        
        // Extract entities as variables
        for entity in context.entities {
            variables[entity.type] = .string(entity.value)
        }
        
        // Extract intent
        variables["intent"] = .string(String(describing: context.intent))
        
        return variables
    }
    
    private func attemptRecovery(error: Error, step: AgentPlanStep) async -> AgentMessage? {
        // Simple recovery: log and continue
        return AgentMessage(
            role: .system,
            content: "Recovery attempted for step: \(step.description)",
            timestamp: Date()
        )
    }
    
    private func generateResponse(for step: AgentPlanStep) async -> String {
        // TODO: Use MLX LLM for response generation
        return "Completed: \(step.description)"
    }
    
    private func createRevisedPlan(
        originalPlan: AgentPlan,
        errors: [AgentError],
        knowledgeContext: [KnowledgeItem]
    ) async -> AgentPlan? {
        // TODO: Use MLX LLM to create revised plan based on errors
        // For now, return nil (no revision)
        return nil
    }
    
    private func extractInsights(from result: ExecutionResult) -> [String] {
        // Extract insights from execution results
        return []
    }
    
    private func buildPlanFromWarmedWorkflow(
        _ warmed: WarmedWorkflow,
        userInput: String,
        tools: [AgentTool]
    ) async -> AgentPlan {
        // Convert warmed workflow plan structure to AgentPlan
        let steps = warmed.planStructure.steps.map { step in
            AgentPlanStep(
                description: step.description,
                toolName: step.toolName,
                arguments: [:] // Will be filled during execution
            )
        }
        return AgentPlan(steps: steps)
    }
}

// MARK: - Supporting Types

public struct ReasoningResult {
    public let trace: ReasoningTrace
    public let messages: [AgentMessage]
    public let knowledgeIntegrated: Bool
}

public struct Understanding {
    public let intent: Intent
    public let entities: [Entity]
    public let context: ReasoningContext
    public let confidence: Double
}

public struct ExecutionResult {
    public let messages: [AgentMessage]
    public let errors: [AgentError]
}

public struct Reflection {
    public let goalsAchieved: Bool
    public let successRate: Double
    public let errors: [AgentError]
    public let shouldTerminate: Bool
    public let revisedPlan: AgentPlan?
    public let insights: [String]
}

public enum Intent {
    case create
    case retrieve
    case update
    case delete
    case analyze
    case general
}

public struct Entity {
    public let type: String
    public let value: String
    public let confidence: Double
}

public struct ReasoningContext {
    public let entities: [Entity]
    public let intent: Intent
    public let temporalContext: TemporalContext
    public let userPreferences: UserPreferences
}

public enum TemporalContext {
    case now
    case past(TimeInterval)
    case future(TimeInterval)
    case specific(Date)
}

public struct UserPreferences {
    // User preferences for reasoning behavior
}

public enum ReasoningStep {
    case understanding(ReasoningContext)
    case planning(AgentPlan)
    case execution(AgentPlanStep)
    case reflection(Reflection)
    case planRevision(AgentPlan)
    case knowledgeIntegration([KnowledgeItem])
}

public class ReasoningTrace {
    public let id: UUID
    public let startedAt: Date
    public private(set) var completedAt: Date?
    private var steps: [ReasoningStep] = []
    
    public init(id: UUID, startedAt: Date) {
        self.id = id
        self.startedAt = startedAt
    }
    
    public func addStep(_ step: ReasoningStep) {
        steps.append(step)
    }
    
    public func getSteps() -> [ReasoningStep] {
        steps
    }
}
