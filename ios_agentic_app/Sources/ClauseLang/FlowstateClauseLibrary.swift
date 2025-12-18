// Flowstate Clause Library: Starter clauses for flowstate scheduling
// Focus blocks, recovery blocks, meeting shields, errands batching
import Foundation

/// Flowstate Clause Library - Pre-defined clauses for scheduling workflows
public struct FlowstateClauseLibrary {
    
    // MARK: - Focus Mode Clauses
    
    /// When in deep work mode, block meetings
    public static let focusModeBlockMeetings = """
    WHEN user.focus_mode == "deep" THEN block_meetings
    """
    
    /// When in deep work mode, enforce minimum block duration
    public static let focusModeMinDuration = """
    WHEN user.focus_mode == "deep" AND block_duration < 45 THEN reject_block
    """
    
    /// When in deep work mode, set context switch penalty
    public static let focusModeContextSwitchPenalty = """
    WHEN user.focus_mode == "deep" THEN set(context_switch_penalty, high)
    """
    
    // MARK: - Recovery Block Clauses
    
    /// After focused work duration, insert recovery block
    public static let recoveryBlockAfterFocus = """
    WHEN focused_duration > 90 THEN insert_recovery_block(duration=10)
    """
    
    /// After long meeting, insert recovery block
    public static let recoveryBlockAfterMeeting = """
    WHEN meeting_duration > 60 THEN insert_recovery_block(duration=15)
    """
    
    /// When focus break detected, insert recovery (not reshuffle)
    public static let recoveryBlockOnBreak = """
    WHEN focus_break_detected == true THEN insert_recovery_block(duration=10)
    """
    
    // MARK: - Meeting Shield Clauses
    
    /// Block meetings during deep work hours
    public static let meetingShieldDeepWork = """
    WHEN user.focus_mode == "deep" AND time_of_day >= 9 AND time_of_day <= 12 THEN block_meetings
    """
    
    /// Protect morning deep work
    public static let meetingShieldMorning = """
    WHEN time_of_day >= 9 AND time_of_day <= 11 AND user.preferred_deep_work == "morning" THEN block_meetings
    """
    
    /// Protect afternoon deep work
    public static let meetingShieldAfternoon = """
    WHEN time_of_day >= 14 AND time_of_day <= 16 AND user.preferred_deep_work == "afternoon" THEN block_meetings
    """
    
    // MARK: - Errands Batching Clauses
    
    /// Cluster errands together to reduce context switching
    public static let errandsBatching = """
    WHEN task_type == "errand" THEN cluster_errands(min_batch_size=3)
    """
    
    /// Batch admin tasks together
    public static let adminBatching = """
    WHEN task_type == "admin" THEN cluster_admin_tasks(min_batch_size=2)
    """
    
    /// Penalize task fragmentation
    public static let penalizeFragmentation = """
    WHEN task_count > 3 AND block_duration < 30 THEN penalize_fragmentation(penalty=high)
    """
    
    // MARK: - Flow Cost Clauses
    
    /// Enforce minimum block size to reduce context switching
    public static let flowCostMinBlockSize = """
    WHEN block_duration < 30 AND task_count > 1 THEN reject_block
    """
    
    /// Cluster by cognitive mode
    public static let flowCostClusterByMode = """
    WHEN cognitive_mode == "creative" THEN cluster_creative_tasks
    """
    
    /// Reduce context switches
    public static let flowCostReduceSwitches = """
    WHEN context_switch_count > 5 THEN optimize_schedule(reduce_switches=true)
    """
    
    // MARK: - Conflict Resolution Clauses
    
    /// Resolve conflicts with minimal disruption
    public static let conflictResolutionMinimal = """
    WHEN calendar_conflict_detected == true THEN resolve_conflict(minimal=true)
    """
    
    /// Learn from user edits
    public static let learnFromEdits = """
    WHEN user_edits_block == true THEN learn_preference(block_id, user_changes)
    """
    
    /// Don't reshuffle entire day on conflict
    public static let conflictLocalAdaptation = """
    WHEN calendar_conflict_detected == true THEN adapt_locally(scope=affected_blocks_only)
    """
    
    // MARK: - Entropy Cap Clauses
    
    /// Cap rescheduling churn
    public static let entropyCap = """
    WHEN rescheduling_churn > 0.22 THEN freeze_plan AND request_user_decision
    """
    
    /// Exit on schedule valid
    public static let exitOnValid = """
    WHEN schedule_valid == true THEN exit_optimization
    """
    
    /// Exit on user cancellation
    public static let exitOnCancel = """
    WHEN user_cancelled == true THEN exit_optimization
    """
    
    // MARK: - Draft-First Workflow Clauses
    
    /// Draft schedule before writing to calendar
    public static let draftFirst = """
    WHEN schedule_ready == true THEN create_draft AND request_user_approval
    """
    
    /// Only write to calendar after approval
    public static let writeAfterApproval = """
    WHEN user_approval == true AND draft_valid == true THEN write_calendar
    """
    
    /// Always reversible with audit trail
    public static let reversibleWithAudit = """
    WHEN action_type == "write_calendar" THEN log_audit_trail AND enable_reversal
    """
    
    // MARK: - Time-Based Clauses
    
    /// Suggest break after long block
    public static let suggestBreak = """
    WHEN block_duration > 120 THEN suggest_break(duration=15)
    """
    
    /// Expire tentative plans after 24 hours
    public static let expireTentativePlans = """
    WHEN tentative_plan_age > 24 THEN expire_plan
    """
    
    // MARK: - Role-Based Clauses
    
    /// Require user approval for calendar writes
    public static let requireApprovalForWrites = """
    WHEN actor == "scheduler_agent" AND action == "write_calendar" THEN require_user_approval
    """
    
    /// User can perform all actions
    public static let userAllActions = """
    WHEN actor == "user" THEN allow_all_actions
    """
    
    // MARK: - Violation Triggers
    
    /// Handle consent revocation
    public static let consentRevoked = """
    WHEN consent_revoked == true THEN notify AND log AND revoke_access AND archive_data
    """
    
    /// Block action on policy violation
    public static let policyViolation = """
    WHEN policy_violation == true THEN block_action AND notify_user
    """
    
    // MARK: - Helper Methods
    
    /// Get all focus mode clauses
    public static var focusModeClauses: [String] {
        [
            focusModeBlockMeetings,
            focusModeMinDuration,
            focusModeContextSwitchPenalty
        ]
    }
    
    /// Get all recovery block clauses
    public static var recoveryBlockClauses: [String] {
        [
            recoveryBlockAfterFocus,
            recoveryBlockAfterMeeting,
            recoveryBlockOnBreak
        ]
    }
    
    /// Get all meeting shield clauses
    public static var meetingShieldClauses: [String] {
        [
            meetingShieldDeepWork,
            meetingShieldMorning,
            meetingShieldAfternoon
        ]
    }
    
    /// Get all errands batching clauses
    public static var errandsBatchingClauses: [String] {
        [
            errandsBatching,
            adminBatching,
            penalizeFragmentation
        ]
    }
    
    /// Get all flow cost clauses
    public static var flowCostClauses: [String] {
        [
            flowCostMinBlockSize,
            flowCostClusterByMode,
            flowCostReduceSwitches
        ]
    }
    
    /// Get all conflict resolution clauses
    public static var conflictResolutionClauses: [String] {
        [
            conflictResolutionMinimal,
            learnFromEdits,
            conflictLocalAdaptation
        ]
    }
    
    /// Get all entropy cap clauses
    public static var entropyCapClauses: [String] {
        [
            entropyCap,
            exitOnValid,
            exitOnCancel
        ]
    }
    
    /// Get all draft-first workflow clauses
    public static var draftFirstClauses: [String] {
        [
            draftFirst,
            writeAfterApproval,
            reversibleWithAudit
        ]
    }
    
    /// Get all clauses
    public static var allClauses: [String] {
        focusModeClauses +
        recoveryBlockClauses +
        meetingShieldClauses +
        errandsBatchingClauses +
        flowCostClauses +
        conflictResolutionClauses +
        entropyCapClauses +
        draftFirstClauses
    }
    
    /// Create ClauseInput from library clause
    public static func createClauseInput(
        rawClause: String,
        id: String? = nil,
        description: String? = nil,
        inputs: [String] = [],
        outputs: [String] = []
    ) -> ClauseInput {
        ClauseInput(
            id: id ?? UUID().uuidString,
            rawClause: rawClause,
            description: description,
            inputs: inputs,
            outputs: outputs
        )
    }
    
    /// Build scheduling workflow KO from library clauses
    public static func buildSchedulingWorkflowKO(
        clauseLang: ClauseLang,
        dagBuilder: DAGBuilder,
        focusModeEnabled: Bool = true,
        recoveryBlocksEnabled: Bool = true,
        meetingShieldsEnabled: Bool = true,
        errandsBatchingEnabled: Bool = true,
        flowCostEnabled: Bool = true
    ) async throws -> KernelObject {
        var clauseInputs: [ClauseInput] = []
        
        // Add clauses based on enabled features
        if focusModeEnabled {
            clauseInputs.append(contentsOf: focusModeClauses.map {
                createClauseInput(rawClause: $0, description: "Focus mode clause")
            })
        }
        
        if recoveryBlocksEnabled {
            clauseInputs.append(contentsOf: recoveryBlockClauses.map {
                createClauseInput(rawClause: $0, description: "Recovery block clause")
            })
        }
        
        if meetingShieldsEnabled {
            clauseInputs.append(contentsOf: meetingShieldClauses.map {
                createClauseInput(rawClause: $0, description: "Meeting shield clause")
            })
        }
        
        if errandsBatchingEnabled {
            clauseInputs.append(contentsOf: errandsBatchingClauses.map {
                createClauseInput(rawClause: $0, description: "Errands batching clause")
            })
        }
        
        if flowCostEnabled {
            clauseInputs.append(contentsOf: flowCostClauses.map {
                createClauseInput(rawClause: $0, description: "Flow cost clause")
            })
        }
        
        // Always include conflict resolution and entropy caps
        clauseInputs.append(contentsOf: conflictResolutionClauses.map {
            createClauseInput(rawClause: $0, description: "Conflict resolution clause")
        })
        
        clauseInputs.append(contentsOf: entropyCapClauses.map {
            createClauseInput(rawClause: $0, description: "Entropy cap clause")
        })
        
        // Build DAG
        let dagNodes = try await dagBuilder.buildDAG(
            from: clauseInputs,
            yields: ["schedule.blocks[]", "tasks.normalized[]", "events.emitted[]"],
            inputs: ["notes.fragment[]", "calendar.events[]", "user.flowstate_model", "constraints.policy"]
        )
        
        // Create loop control
        let loop = LoopControl(
            bounds: 6,
            entropyCap: 0.22,
            retryLimit: 2,
            retryScope: "DAG-local",
            exitConditions: ["schedule_valid == true", "user_cancelled == true"]
        )
        
        // Create reflex triggers
        let reflex = ReflexTriggers(
            triggerMap: [
                "calendar_conflict_detected": "resolve_conflict_clause",
                "user_edits_block": "learn_preference_clause",
                "focus_break_detected": "insert_recovery_block_clause"
            ],
            entropyHint: 0.15,
            kernel: "flowstate"
        )
        
        // Collapse to KO
        return await dagBuilder.collapseToKO(
            dagNodes: dagNodes,
            clauseId: "flowstate.session.plan.v1",
            type: .scheduling,
            role: .agent,
            inputs: ["notes.fragment[]", "calendar.events[]", "user.flowstate_model", "constraints.policy"],
            yields: ["schedule.blocks[]", "tasks.normalized[]", "events.emitted[]"],
            loop: loop,
            reflex: reflex
        )
    }
}
