// Reflex Trigger System: Event-driven clause activation for live adaptation
// Enables reflexive scheduling without chaos
import Foundation

/// Reflex Trigger System - Handles event-driven clause activation
public actor ReflexTriggerSystem {
    private var triggerMap: [String: String] = [:] // event -> clause_id
    private var activeReflexes: [String: ReflexState] = [:]
    private let clauseLang: ClauseLang
    private let dagBuilder: DAGBuilder
    
    public init(clauseLang: ClauseLang, dagBuilder: DAGBuilder) {
        self.clauseLang = clauseLang
        self.dagBuilder = dagBuilder
    }
    
    /// Register reflex triggers from a KO
    public func registerTriggers(from ko: KernelObject) {
        guard let reflex = ko.reflex else { return }
        triggerMap = reflex.triggerMap
    }
    
    /// Handle an event and trigger appropriate clauses
    public func handleEvent(
        _ event: ReflexEvent,
        context: ClauseContext,
        currentKO: KernelObject?
    ) async throws -> ReflexResult {
        // Check if event has a registered trigger
        guard let clauseId = triggerMap[event.type] else {
            return ReflexResult(triggered: false, message: "No trigger registered for event: \(event.type)")
        }
        
        // Load or create the reflex clause
        let reflexClause = try await loadReflexClause(clauseId: clauseId, event: event)
        
        // Execute reflex clause
        let ast = try await clauseLang.parse(reflexClause.raw)
        let result = try await clauseLang.execute(ast, context: context)
        
        // Update reflex state
        let state = ReflexState(
            event: event,
            clauseId: clauseId,
            executedAt: Date(),
            result: result
        )
        activeReflexes[event.id] = state
        
        // Check if we need to adapt the current KO
        if let ko = currentKO {
            let adaptedKO = try await adaptKO(ko, basedOn: event, reflexResult: result)
            return ReflexResult(
                triggered: true,
                message: "Reflex triggered: \(clauseId)",
                adaptedKO: adaptedKO,
                reflexState: state
            )
        }
        
        return ReflexResult(
            triggered: true,
            message: "Reflex triggered: \(clauseId)",
            reflexState: state
        )
    }
    
    /// Adapt KO based on reflex event (local adaptation, don't reshuffle entire day)
    private func adaptKO(
        _ ko: KernelObject,
        basedOn event: ReflexEvent,
        reflexResult: ClauseResult
    ) async throws -> KernelObject {
        // Local adaptation: only modify affected parts, not entire schedule
        
        switch event.type {
        case "calendar_conflict_detected":
            // Resolve conflict locally - only affected blocks
            return try await resolveConflictLocally(ko, event: event)
            
        case "user_edits_block":
            // Learn preference - update user model, don't reshuffle
            return try await learnPreference(ko, event: event)
            
        case "focus_break_detected":
            // Insert recovery block - local insertion, not reshuffle
            return try await insertRecoveryBlock(ko, event: event)
            
        default:
            // No adaptation needed
            return ko
        }
    }
    
    /// Resolve conflict with minimal disruption (local scope)
    private func resolveConflictLocally(
        _ ko: KernelObject,
        event: ReflexEvent
    ) async throws -> KernelObject {
        // Only modify affected blocks, not entire schedule
        // This is the key: local adaptation, not global reshuffle
        
        // Extract affected block IDs from event data
        let affectedBlockIds = event.data?["affected_blocks"]?.components(separatedBy: ",") ?? []
        
        // Create new DAG nodes for conflict resolution (only for affected blocks)
        var newNodes = ko.dagNodes
        
        // Add conflict resolution node (scoped to affected blocks)
        let conflictClause = Clause(
            raw: "WHEN calendar_conflict_detected == true THEN resolve_conflict(minimal=true, scope=affected_blocks_only)",
            ast: ClauseASTRepresentation(
                condition: ConditionRepresentation(
                    lhs: "calendar_conflict_detected",
                    op: "==",
                    rhs: "true"
                ),
                action: ActionRepresentation(
                    type: "functionCall",
                    function: "resolve_conflict",
                    arguments: ["minimal=true", "scope=affected_blocks_only"]
                ),
                originalClause: "WHEN calendar_conflict_detected == true THEN resolve_conflict(minimal=true, scope=affected_blocks_only)"
            ),
            description: "Resolve conflict locally"
        )
        
        let conflictNode = DAGNode(
            id: "conflict_resolution_\(UUID().uuidString.prefix(8))",
            clause: conflictClause,
            dependencies: affectedBlockIds, // Only depends on affected blocks
            inputs: ["calendar_conflict_detected", "affected_blocks"],
            outputs: ["resolved_schedule"]
        )
        
        newNodes.append(conflictNode)
        
        // Return adapted KO (minimal changes)
        return KernelObject(
            clauseId: ko.clauseId,
            type: ko.type,
            role: ko.role,
            inputs: ko.inputs,
            yields: ko.yields,
            dagNodes: newNodes,
            logic: ko.logic,
            loop: ko.loop,
            reflex: ko.reflex,
            composition: ko.composition,
            metadata: KernelMetadata(
                version: ko.metadata.version,
                validated: ko.metadata.validated,
                siglereChecksum: ko.metadata.siglereChecksum,
                createdAt: ko.metadata.createdAt,
                updatedAt: Date()
            )
        )
    }
    
    /// Learn preference from user edit (update model, don't reshuffle)
    private func learnPreference(
        _ ko: KernelObject,
        event: ReflexEvent
    ) async throws -> KernelObject {
        // Learn preference - update user model, not schedule
        // This is about learning, not immediate adaptation
        
        let learnClause = Clause(
            raw: "WHEN user_edits_block == true THEN learn_preference(block_id, user_changes)",
            ast: ClauseASTRepresentation(
                condition: ConditionRepresentation(
                    lhs: "user_edits_block",
                    op: "==",
                    rhs: "true"
                ),
                action: ActionRepresentation(
                    type: "functionCall",
                    function: "learn_preference",
                    arguments: ["block_id", "user_changes"]
                ),
                originalClause: "WHEN user_edits_block == true THEN learn_preference(block_id, user_changes)"
            ),
            description: "Learn from user edit"
        )
        
        // Add learning node (doesn't modify schedule, just updates model)
        var newNodes = ko.dagNodes
        let learnNode = DAGNode(
            id: "learn_preference_\(UUID().uuidString.prefix(8))",
            clause: learnClause,
            dependencies: [],
            inputs: ["user_edits_block", "block_id", "user_changes"],
            outputs: ["updated_user_model"]
        )
        newNodes.append(learnNode)
        
        return KernelObject(
            clauseId: ko.clauseId,
            type: ko.type,
            role: ko.role,
            inputs: ko.inputs,
            yields: ko.yields,
            dagNodes: newNodes,
            logic: ko.logic,
            loop: ko.loop,
            reflex: ko.reflex,
            composition: ko.composition,
            metadata: KernelMetadata(
                version: ko.metadata.version,
                validated: ko.metadata.validated,
                siglereChecksum: ko.metadata.siglereChecksum,
                createdAt: ko.metadata.createdAt,
                updatedAt: Date()
            )
        )
    }
    
    /// Insert recovery block (local insertion, not reshuffle)
    private func insertRecoveryBlock(
        _ ko: KernelObject,
        event: ReflexEvent
    ) async throws -> KernelObject {
        // Insert recovery block locally - don't reshuffle entire day
        
        let recoveryClause = Clause(
            raw: "WHEN focus_break_detected == true THEN insert_recovery_block(duration=10)",
            ast: ClauseASTRepresentation(
                condition: ConditionRepresentation(
                    lhs: "focus_break_detected",
                    op: "==",
                    rhs: "true"
                ),
                action: ActionRepresentation(
                    type: "functionCall",
                    function: "insert_recovery_block",
                    arguments: ["duration=10"]
                ),
                originalClause: "WHEN focus_break_detected == true THEN insert_recovery_block(duration=10)"
            ),
            description: "Insert recovery block"
        )
        
        // Add recovery block node (local insertion)
        var newNodes = ko.dagNodes
        let recoveryNode = DAGNode(
            id: "recovery_block_\(UUID().uuidString.prefix(8))",
            clause: recoveryClause,
            dependencies: [], // Independent insertion
            inputs: ["focus_break_detected"],
            outputs: ["recovery_block_inserted"]
        )
        newNodes.append(recoveryNode)
        
        return KernelObject(
            clauseId: ko.clauseId,
            type: ko.type,
            role: ko.role,
            inputs: ko.inputs,
            yields: ko.yields,
            dagNodes: newNodes,
            logic: ko.logic,
            loop: ko.loop,
            reflex: ko.reflex,
            composition: ko.composition,
            metadata: KernelMetadata(
                version: ko.metadata.version,
                validated: ko.metadata.validated,
                siglereChecksum: ko.metadata.siglereChecksum,
                createdAt: ko.metadata.createdAt,
                updatedAt: Date()
            )
        )
    }
    
    /// Load reflex clause by ID
    private func loadReflexClause(clauseId: String, event: ReflexEvent) async throws -> Clause {
        // In a real implementation, this would load from storage
        // For now, return a default clause based on event type
        
        switch clauseId {
        case "resolve_conflict_clause":
            return Clause(
                raw: FlowstateClauseLibrary.conflictResolutionMinimal,
                ast: try await parseClauseAST(FlowstateClauseLibrary.conflictResolutionMinimal),
                description: "Resolve conflict with minimal disruption"
            )
        case "learn_preference_clause":
            return Clause(
                raw: FlowstateClauseLibrary.learnFromEdits,
                ast: try await parseClauseAST(FlowstateClauseLibrary.learnFromEdits),
                description: "Learn from user edits"
            )
        case "insert_recovery_block_clause":
            return Clause(
                raw: FlowstateClauseLibrary.recoveryBlockOnBreak,
                ast: try await parseClauseAST(FlowstateClauseLibrary.recoveryBlockOnBreak),
                description: "Insert recovery block on focus break"
            )
        default:
            throw ReflexTriggerError.unknownClause(clauseId)
        }
    }
    
    private func parseClauseAST(_ raw: String) async throws -> ClauseASTRepresentation {
        let ast = try await clauseLang.parse(raw)
        return ClauseASTRepresentation(from: ast)
    }
    
    /// Get active reflex states
    public func getActiveReflexes() -> [ReflexState] {
        Array(activeReflexes.values)
    }
    
    /// Clear old reflexes
    public func clearOldReflexes(olderThan: TimeInterval = 3600) {
        let cutoff = Date().addingTimeInterval(-olderThan)
        activeReflexes = activeReflexes.filter { $0.value.executedAt > cutoff }
    }
}

// MARK: - Supporting Types

public struct ReflexEvent: Codable, Identifiable {
    public let id: String
    public let type: String
    public let timestamp: Date
    public let data: [String: String]?
    
    public init(
        id: String = UUID().uuidString,
        type: String,
        timestamp: Date = Date(),
        data: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.data = data
    }
}

public struct ReflexState: Codable {
    public let event: ReflexEvent
    public let clauseId: String
    public let executedAt: Date
    public let result: ClauseResult
}

public struct ReflexResult: Codable {
    public let triggered: Bool
    public let message: String
    public let adaptedKO: KernelObject?
    public let reflexState: ReflexState?
    
    public init(
        triggered: Bool,
        message: String,
        adaptedKO: KernelObject? = nil,
        reflexState: ReflexState? = nil
    ) {
        self.triggered = triggered
        self.message = message
        self.adaptedKO = adaptedKO
        self.reflexState = reflexState
    }
}

public enum ReflexTriggerError: Error, LocalizedError {
    case unknownClause(String)
    case invalidEvent(String)
    
    public var errorDescription: String? {
        switch self {
        case .unknownClause(let id):
            return "Unknown reflex clause: \(id)"
        case .invalidEvent(let type):
            return "Invalid reflex event: \(type)"
        }
    }
}
