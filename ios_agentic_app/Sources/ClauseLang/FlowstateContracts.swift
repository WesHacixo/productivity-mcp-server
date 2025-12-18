// Flowstate Contract Library: Default ClauseLang contracts for scheduling
import Foundation

/// Default flowstate contracts that users can inspect and customize
public struct FlowstateContracts {
    
    /// Default contract for deep work mode
    public static let deepWorkContract = FlowstateContract(
        id: "flowstate.deep_work.v1",
        clauses: [
            FlowstateContract.Clause(
                raw: "WHEN user.focus_mode == \"deep\" THEN set(block.min_duration_minutes, 45)",
                description: "In deep work mode, schedule blocks of at least 45 minutes"
            ),
            FlowstateContract.Clause(
                raw: "WHEN user.focus_mode == \"deep\" THEN set(block.context_switch_penalty, high)",
                description: "Penalize context switching during deep work"
            ),
            FlowstateContract.Clause(
                raw: "WHEN user.focus_mode == \"deep\" AND notes_count > 0 THEN normalize_fragments",
                description: "Normalize notes when in deep work mode"
            )
        ],
        reflex: FlowstateContract.ReflexMap(
            triggerMap: [
                "focus_break_detected": "WHEN focus_break_detected == true THEN insert_recovery_block_clause"
            ]
        )
    )
    
    /// Default contract for meeting scheduling
    public static let meetingContract = FlowstateContract(
        id: "flowstate.meetings.v1",
        clauses: [
            FlowstateContract.Clause(
                raw: "WHEN user.focus_mode == \"deep\" THEN set(block.allow_meetings, false)",
                description: "Don't schedule meetings during deep work"
            ),
            FlowstateContract.Clause(
                raw: "WHEN calendar_conflict_detected == true THEN resolve_conflict_clause",
                description: "Resolve calendar conflicts automatically"
            )
        ],
        reflex: FlowstateContract.ReflexMap(
            triggerMap: [
                "calendar_conflict_detected": "WHEN calendar_conflict_detected == true THEN resolve_conflict_clause"
            ]
        )
    )
    
    /// Default contract for recovery blocks
    public static let recoveryContract = FlowstateContract(
        id: "flowstate.recovery.v1",
        clauses: [
            FlowstateContract.Clause(
                raw: "WHEN block.duration_minutes >= 90 THEN insert_recovery_block",
                description: "After 90 minutes of work, insert a 10-minute recovery block"
            )
        ],
        reflex: nil
    )
    
    /// Default contract for entropy control
    public static let entropyContract = FlowstateContract(
        id: "flowstate.entropy.v1",
        clauses: [
            FlowstateContract.Clause(
                raw: "WHEN entropy >= 0.22 THEN freeze_schedule",
                description: "When entropy cap is reached, freeze schedule and ask for approval"
            )
        ],
        reflex: nil
    )
    
    /// Default contract for user preferences
    public static let preferenceContract = FlowstateContract(
        id: "flowstate.preferences.v1",
        clauses: [
            FlowstateContract.Clause(
                raw: "WHEN user_edits_block == true THEN learn_preference_clause",
                description: "Learn from user edits to improve future scheduling"
            )
        ],
        reflex: FlowstateContract.ReflexMap(
            triggerMap: [
                "user_edits_block": "WHEN user_edits_block == true THEN learn_preference_clause"
            ]
        )
    )
    
    /// All default contracts
    public static let allContracts: [FlowstateContract] = [
        deepWorkContract,
        meetingContract,
        recoveryContract,
        entropyContract,
        preferenceContract
    ]
}
