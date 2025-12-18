// KO Executor: Executes Kernel Objects as workflow orchestrator
// Integrates with ReasoningEngine for agent workflow execution
import Foundation

/// Executes Kernel Objects as workflow orchestrator
public actor KOExecutor {
    private let clauseLang: ClauseLang
    private let reflexTriggerSystem: ReflexTriggerSystem?
    private let entropyCapEnforcer: EntropyCapEnforcer?
    
    public init(
        clauseLang: ClauseLang,
        reflexTriggerSystem: ReflexTriggerSystem? = nil,
        entropyCapEnforcer: EntropyCapEnforcer? = nil
    ) {
        self.clauseLang = clauseLang
        self.reflexTriggerSystem = reflexTriggerSystem
        self.entropyCapEnforcer = entropyCapEnforcer
    }
    
    /// Execute a Kernel Object
    public func execute(
        _ ko: KernelObject,
        context: ClauseContext,
        maxIterations: Int? = nil
    ) async throws -> KOExecutionResult {
        let startTime = Date()
        var executionState = KOExecutionState(koId: ko.id)
        
        // Register reflex triggers if available
        if let reflex = reflexTriggerSystem {
            await reflex.registerTriggers(from: ko)
        }
        
        // Determine max iterations from loop control or parameter
        let maxIters = maxIterations ?? ko.loop?.bounds ?? 10
        
        // Execute DAG nodes in topological order
        var outputs: [String: AnyCodable] = [:]
        var currentKO = ko
        
        for iteration in 0..<maxIters {
            executionState.iteration = iteration
            
            // Check entropy cap
            if let enforcer = entropyCapEnforcer {
                let currentEntropy = await getCurrentEntropy()
                if await enforcer.shouldFreeze(ko: currentKO, currentEntropy: currentEntropy) {
                    let event = KOEvent(
                        type: .entropyCapReached,
                        message: "Entropy cap reached: \(currentEntropy)",
                        data: ["entropy": String(currentEntropy)]
                    )
                    executionState.events.append(event)
                    
                    // Request user decision
                    let decisionRequest = await enforcer.requestUserDecision(
                        reason: "Rescheduling churn exceeded entropy cap",
                        options: ["Continue", "Freeze plan", "Reset"]
                    )
                    
                    // For now, exit on entropy cap (in real implementation, wait for user decision)
                    return KOExecutionResult(
                        koId: ko.id,
                        success: false,
                        outputs: outputs,
                        executionState: executionState,
                        error: "Entropy cap exceeded",
                        duration: Date().timeIntervalSince(startTime)
                    )
                }
            }
            
            // Check exit conditions
            if let loop = ko.loop {
                for exitCondition in loop.exitConditions {
                    if try await evaluateExitCondition(exitCondition, context: context) {
                        let event = KOEvent(
                            type: .exitConditionMet,
                            message: "Exit condition met: \(exitCondition)"
                        )
                        executionState.events.append(event)
                        
                        return KOExecutionResult(
                            koId: ko.id,
                            success: true,
                            outputs: outputs,
                            executionState: executionState,
                            duration: Date().timeIntervalSince(startTime)
                        )
                    }
                }
            }
            
            // Execute DAG nodes in order
            for node in currentKO.dagNodes {
                // Skip if already completed
                if executionState.completedNodes.contains(node.id) {
                    continue
                }
                
                // Check dependencies
                let allDepsCompleted = node.dependencies.allSatisfy { depId in
                    executionState.completedNodes.contains(depId)
                }
                
                if !allDepsCompleted {
                    continue // Wait for dependencies
                }
                
                // Execute node
                executionState.currentNodeId = node.id
                
                let nodeEvent = KOEvent(
                    type: .nodeStarted,
                    nodeId: node.id,
                    message: "Executing node: \(node.id)"
                )
                executionState.events.append(nodeEvent)
                
                do {
                    // Parse and execute clause
                    let ast = try await clauseLang.parse(node.clause.raw)
                    let result = try await clauseLang.execute(ast, context: context)
                    
                    // Update outputs from node outputs
                    for output in node.outputs {
                        outputs[output] = AnyCodable(result.message)
                    }
                    
                    // Mark as completed
                    executionState.completedNodes.insert(node.id)
                    
                    let completeEvent = KOEvent(
                        type: .nodeCompleted,
                        nodeId: node.id,
                        message: "Node completed: \(result.message)"
                    )
                    executionState.events.append(completeEvent)
                    
                } catch {
                    // Handle node failure
                    let failEvent = KOEvent(
                        type: .nodeFailed,
                        nodeId: node.id,
                        message: "Node failed: \(error.localizedDescription)"
                    )
                    executionState.events.append(failEvent)
                    
                    // Check retry limit
                    if executionState.retryCount < (ko.loop?.retryLimit ?? 2) {
                        executionState.retryCount += 1
                        // Retry node (in real implementation, would retry with backoff)
                        continue
                    } else {
                        // Max retries exceeded
                        return KOExecutionResult(
                            koId: ko.id,
                            success: false,
                            outputs: outputs,
                            executionState: executionState,
                            error: "Node \(node.id) failed after retries: \(error.localizedDescription)",
                            duration: Date().timeIntervalSince(startTime)
                        )
                    }
                }
            }
            
            // Check if all nodes completed
            if executionState.completedNodes.count == currentKO.dagNodes.count {
                // All nodes completed successfully
                return KOExecutionResult(
                    koId: ko.id,
                    success: true,
                    outputs: outputs,
                    executionState: executionState,
                    duration: Date().timeIntervalSince(startTime)
                )
            }
            
            // Update entropy (if rescheduling occurred)
            if let enforcer = entropyCapEnforcer {
                await updateEntropyForIteration(iteration, ko: currentKO)
            }
        }
        
        // Max iterations reached
        return KOExecutionResult(
            koId: ko.id,
            success: false,
            outputs: outputs,
            executionState: executionState,
            error: "Max iterations (\(maxIters)) reached",
            duration: Date().timeIntervalSince(startTime)
        )
    }
    
    /// Handle reflex event during execution
    public func handleReflexEvent(
        _ event: ReflexEvent,
        currentKO: KernelObject,
        context: ClauseContext
    ) async throws -> KernelObject? {
        guard let reflex = reflexTriggerSystem else {
            return nil
        }
        
        let result = try await reflex.handleEvent(event, context: context, currentKO: currentKO)
        
        if result.triggered, let adaptedKO = result.adaptedKO {
            // Return adapted KO for continued execution
            return adaptedKO
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func evaluateExitCondition(
        _ condition: String,
        context: ClauseContext
    ) async throws -> Bool {
        // Parse and evaluate exit condition
        // Simple implementation: check if condition variable is true in context
        let parts = condition.components(separatedBy: "==")
        if parts.count == 2 {
            let variable = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            
            if let contextValue = context.variables[variable] {
                let expectedValue = try parseClauseValue(value)
                return contextValue == expectedValue
            }
        }
        
        return false
    }
    
    private func parseClauseValue(_ valueStr: String) throws -> ClauseValue {
        // Parse value string to ClauseValue
        if valueStr.lowercased() == "true" {
            return .boolean(true)
        }
        if valueStr.lowercased() == "false" {
            return .boolean(false)
        }
        if let number = Double(valueStr) {
            return .number(number)
        }
        if valueStr.hasPrefix("\"") && valueStr.hasSuffix("\"") {
            return .string(String(valueStr.dropFirst().dropLast()))
        }
        return .identifier(valueStr)
    }
    
    private func getCurrentEntropy() async -> Double {
        // Get current entropy from enforcer's tracker
        guard let enforcer = entropyCapEnforcer else {
            return 0.0
        }
        // In real implementation, would access entropy tracker
        return 0.0 // Placeholder
    }
    
    private func updateEntropyForIteration(
        _ iteration: Int,
        ko: KernelObject
    ) async {
        // Update entropy based on rescheduling in this iteration
        // In real implementation, would track actual rescheduling actions
    }
}
