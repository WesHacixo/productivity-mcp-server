// Flowstate Scheduler: ClauseLang-powered scheduling with flow-cost optimization
// Implements reflexive scheduling, entropy caps, and flow-cost minimization
import Foundation

/// Flowstate scheduler using ClauseLang contracts for predictable, reflexive scheduling
public actor FlowstateScheduler {
    private let clauseLang: ClauseLang
    private let schedulingReasoner: SchedulingReasoner
    private var activeContracts: [FlowstateContract] = []
    private var entropyAccumulator: Double = 0.0
    private let maxEntropy: Double = 0.22 // From ClauseLang schema
    
    public init(
        clauseLang: ClauseLang,
        schedulingReasoner: SchedulingReasoner
    ) {
        self.clauseLang = clauseLang
        self.schedulingReasoner = schedulingReasoner
    }
    
    /// Schedule with flow-cost optimization and ClauseLang contracts
    public func scheduleWithFlowstate(
        request: String,
        userFlowstate: UserFlowstate,
        constraints: SchedulingConstraints
    ) async throws -> FlowstateScheduleResult {
        // Check entropy cap
        guard entropyAccumulator < maxEntropy else {
            return FlowstateScheduleResult(
                schedule: nil,
                message: "Entropy cap reached. Please review and approve current schedule before continuing.",
                clauses: [],
                flowCost: 0.0,
                entropy: entropyAccumulator
            )
        }
        
        // Build ClauseLang context
        let context = buildClauseContext(
            request: request,
            flowstate: userFlowstate,
            constraints: constraints
        )
        
        // Execute active contracts
        var executedClauses: [ExecutedClause] = []
        for contract in activeContracts {
            for clause in contract.clauses {
                do {
                    let ast = try await clauseLang.parse(clause.raw)
                    if clauseLang.evaluate(ast, context: context) {
                        let result = try await clauseLang.execute(ast, context: context)
                        executedClauses.append(ExecutedClause(
                            clause: clause,
                            result: result,
                            context: context
                        ))
                    }
                } catch {
                    // Log but continue
                    print("Clause execution error: \(error)")
                }
            }
        }
        
        // Apply flow-cost optimization
        let optimized = try await optimizeFlowCost(
            request: request,
            flowstate: userFlowstate,
            constraints: constraints,
            context: context
        )
        
        // Calculate entropy increase
        let entropyIncrease = calculateEntropyIncrease(optimized)
        entropyAccumulator += entropyIncrease
        
        // Execute scheduling
        let scheduleResult = try await schedulingReasoner.schedule(optimized.request)
        
        return FlowstateScheduleResult(
            schedule: scheduleResult,
            message: scheduleResult.message,
            clauses: executedClauses,
            flowCost: optimized.flowCost,
            entropy: entropyAccumulator
        )
    }
    
    /// Handle reflexive triggers (user edits, conflicts, breaks)
    public func handleReflexTrigger(
        trigger: ReflexTrigger,
        currentSchedule: [ScheduledItem]
    ) async throws -> ReflexResult {
        // Find matching reflex clause
        for contract in activeContracts {
            if let reflex = contract.reflex, let clause = reflex.triggerMap[trigger.type] {
                // Execute reflex clause
                let context = buildReflexContext(trigger: trigger, schedule: currentSchedule)
                let ast = try await clauseLang.parse(clause)
                let result = try await clauseLang.execute(ast, context: context)
                
                return ReflexResult(
                    trigger: trigger,
                    clause: clause,
                    result: result,
                    actions: extractActions(result)
                )
            }
        }
        
        // No matching reflex - return default handling
        return ReflexResult(
            trigger: trigger,
            clause: nil,
            result: ClauseResult(success: false, message: "No reflex clause found"),
            actions: []
        )
    }
    
    /// Add a flowstate contract
    public func addContract(_ contract: FlowstateContract) async {
        activeContracts.append(contract)
    }
    
    /// Reset entropy (after user approval)
    public func resetEntropy() async {
        entropyAccumulator = 0.0
    }
    
    // MARK: - Private Methods
    
    private func buildClauseContext(
        request: String,
        flowstate: UserFlowstate,
        constraints: SchedulingConstraints
    ) -> ClauseContext {
        let context = ClauseContext()
        
        // Add flowstate variables
        context.variables["user.focus_mode"] = .string(flowstate.focusMode.rawValue)
        context.variables["user.flow_cost"] = .number(flowstate.currentFlowCost)
        context.variables["constraints.policy.allow_autowrite"] = .boolean(constraints.allowAutoWrite)
        context.variables["constraints.policy.min_block_duration"] = .number(Double(constraints.minBlockDurationMinutes))
        
        // Add scheduling variables
        context.variables["notes_count"] = .number(Double(flowstate.pendingNotes.count))
        context.variables["normalized_ready"] = .boolean(flowstate.normalizedReady)
        context.variables["clusters_ready"] = .boolean(flowstate.clustersReady)
        context.variables["ranked_ready"] = .boolean(flowstate.rankedReady)
        context.variables["schedule_valid"] = .boolean(flowstate.scheduleValid)
        
        return context
    }
    
    private func optimizeFlowCost(
        request: String,
        flowstate: UserFlowstate,
        constraints: SchedulingConstraints,
        context: ClauseContext
    ) async throws -> OptimizedRequest {
        // Flow-cost optimization: minimize context switching
        
        // Cluster tasks by cognitive mode
        let clusters = clusterByCognitiveMode(flowstate.pendingTasks)
        
        // Rank by flow cost (lower is better)
        let ranked = rankByFlowCost(clusters, flowstate: flowstate)
        
        // Allocate time blocks with minimum duration
        let blocks = allocateTimeBlocks(
            ranked,
            minDuration: constraints.minBlockDurationMinutes,
            flowstate: flowstate
        )
        
        // Calculate total flow cost
        let flowCost = calculateTotalFlowCost(blocks)
        
        // Build optimized request
        let optimizedRequest = buildOptimizedRequest(blocks, originalRequest: request)
        
        return OptimizedRequest(
            request: optimizedRequest,
            flowCost: flowCost,
            blocks: blocks
        )
    }
    
    private func clusterByCognitiveMode(_ tasks: [TaskItem]) -> [TaskCluster] {
        // Simple clustering by task type
        var clusters: [String: [TaskItem]] = [:]
        
        for task in tasks {
            let mode = determineCognitiveMode(task)
            clusters[mode, default: []].append(task)
        }
        
        return clusters.map { TaskCluster(mode: $0.key, tasks: $0.value) }
    }
    
    private func determineCognitiveMode(_ task: TaskItem) -> String {
        let lower = task.title.lowercased()
        if lower.contains("meeting") || lower.contains("call") {
            return "social"
        } else if lower.contains("review") || lower.contains("code") {
            return "deep"
        } else if lower.contains("email") || lower.contains("admin") {
            return "shallow"
        } else {
            return "general"
        }
    }
    
    private func rankByFlowCost(_ clusters: [TaskCluster], flowstate: UserFlowstate) -> [TaskCluster] {
        // Rank by flow cost (penalize context switching)
        return clusters.sorted { cluster1, cluster2 in
            let cost1 = calculateClusterFlowCost(cluster1, flowstate: flowstate)
            let cost2 = calculateClusterFlowCost(cluster2, flowstate: flowstate)
            return cost1 < cost2
        }
    }
    
    private func calculateClusterFlowCost(_ cluster: TaskCluster, flowstate: UserFlowstate) -> Double {
        // Flow cost = context switch penalty + cognitive mode mismatch
        var cost = 0.0
        
        // Context switch penalty
        if cluster.mode != flowstate.focusMode.rawValue {
            cost += 0.5
        }
        
        // Task count penalty (more tasks = higher cost)
        cost += Double(cluster.tasks.count) * 0.1
        
        return cost
    }
    
    private func allocateTimeBlocks(
        _ clusters: [TaskCluster],
        minDuration: Int,
        flowstate: UserFlowstate
    ) -> [TimeBlock] {
        var blocks: [TimeBlock] = []
        var currentTime = Date()
        
        for cluster in clusters {
            let duration = max(minDuration, estimateDuration(cluster.tasks))
            let block = TimeBlock(
                start: currentTime,
                duration: TimeInterval(duration * 60),
                tasks: cluster.tasks,
                cognitiveMode: cluster.mode
            )
            blocks.append(block)
            currentTime = currentTime.addingTimeInterval(TimeInterval(duration * 60))
        }
        
        return blocks
    }
    
    private func estimateDuration(_ tasks: [TaskItem]) -> Int {
        // Simple estimation: 30 minutes per task
        return tasks.count * 30
    }
    
    private func calculateTotalFlowCost(_ blocks: [TimeBlock]) -> Double {
        var totalCost = 0.0
        var previousMode: String? = nil
        
        for block in blocks {
            // Context switch cost
            if let prev = previousMode, prev != block.cognitiveMode {
                totalCost += 0.3
            }
            previousMode = block.cognitiveMode
            
            // Block duration cost (longer blocks = lower cost per task)
            totalCost += Double(block.tasks.count) / Double(block.duration / 3600)
        }
        
        return totalCost
    }
    
    private func buildOptimizedRequest(_ blocks: [TimeBlock], originalRequest: String) -> String {
        // Build request from optimized blocks
        var requests: [String] = []
        
        for block in blocks {
            let taskTitles = block.tasks.map { $0.title }.joined(separator: ", ")
            let timeStr = DateFormatter.localizedString(from: block.start, dateStyle: .none, timeStyle: .short)
            requests.append("Schedule \(taskTitles) at \(timeStr)")
        }
        
        return requests.joined(separator: ". ")
    }
    
    private func calculateEntropyIncrease(_ optimized: OptimizedRequest) -> Double {
        // Entropy = measure of schedule churn
        // More changes = higher entropy
        return optimized.flowCost * 0.1 // Simple heuristic
    }
    
    private func buildReflexContext(trigger: ReflexTrigger, schedule: [ScheduledItem]) -> ClauseContext {
        let context = ClauseContext()
        context.variables["trigger.type"] = .string(trigger.type.rawValue)
        context.variables["schedule.count"] = .number(Double(schedule.count))
        return context
    }
    
    private func extractActions(_ result: ClauseResult) -> [String] {
        // Extract actions from clause result
        return [result.message]
    }
}

// MARK: - Supporting Types

public struct FlowstateContract {
    public let id: String
    public let clauses: [Clause]
    public let reflex: ReflexMap?
    
    public struct Clause {
        public let raw: String
        public let description: String
    }
    
    public struct ReflexMap {
        public let triggerMap: [String: String] // trigger type -> clause
    }
}

public struct UserFlowstate {
    public let focusMode: FocusMode
    public let currentFlowCost: Double
    public let pendingNotes: [String]
    public let pendingTasks: [TaskItem]
    public let normalizedReady: Bool
    public let clustersReady: Bool
    public let rankedReady: Bool
    public let scheduleValid: Bool
    
    public enum FocusMode: String {
        case deep = "deep"
        case shallow = "shallow"
        case social = "social"
        case general = "general"
    }
}

public struct SchedulingConstraints {
    public let allowAutoWrite: Bool
    public let minBlockDurationMinutes: Int
    public let maxContextSwitches: Int
}

public struct FlowstateScheduleResult {
    public let schedule: SchedulingResult?
    public let message: String
    public let clauses: [ExecutedClause]
    public let flowCost: Double
    public let entropy: Double
}

public struct ExecutedClause {
    public let clause: FlowstateContract.Clause
    public let result: ClauseResult
    public let context: ClauseContext
}

public struct ReflexTrigger {
    public let type: TriggerType
    public let data: [String: Any]
    
    public enum TriggerType: String {
        case calendarConflictDetected = "calendar_conflict_detected"
        case userEditsBlock = "user_edits_block"
        case focusBreakDetected = "focus_break_detected"
    }
}

public struct ReflexResult {
    public let trigger: ReflexTrigger
    public let clause: String?
    public let result: ClauseResult
    public let actions: [String]
}

public struct OptimizedRequest {
    public let request: String
    public let flowCost: Double
    public let blocks: [TimeBlock]
}

public struct TaskCluster {
    public let mode: String
    public let tasks: [TaskItem]
}

public struct TimeBlock {
    public let start: Date
    public let duration: TimeInterval
    public let tasks: [TaskItem]
    public let cognitiveMode: String
}
