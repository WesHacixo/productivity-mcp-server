# ClauseLang Flowstate Implementation Plan

**Date:** 2025-12-17  
**Status:** Aligned with ClauseLang Definition

## 🎯 ClauseLang Definition (Refined Understanding)

ClauseLang is **not just a rule language** - it's a **compilation target for agent contracts** that bridges:
- **Human Intent** (prose, notes, "do X when Y") 
- **Machine Execution** (validated schemas, ASTs, DAG plans, triggers, retries)

### Core Pipeline

1. **Validate** → Zod/JSON Schema rejects malformed clauses early
2. **Interpret** → AST → typed "condition/action" objects
3. **Compose** → Multiple clauses → DAG + roles + jurisdiction/context
4. **Execute** → Orchestrator runs actions, emits events, enforces retries/entropy caps
5. **Audit** → Render Ricardian hybrid (prose + machine form) for user trust/debugging

### Surface Syntax (Minimal PEG)

```
WHEN <Identifier> <Operator> <Value> THEN <Action>
Operators: ==, !=, >, <, >=, <=
Values: true/false, "strings", numbers
```

### KO (Kernel Object) - The Executable Artifact

After parsing + validation + composition → **KO** = what the orchestrator actually runs.

Includes:
- `dag_nodes` - DAG structure
- `logic` - conditions and actions
- `loop` - bounds, entropy caps, retry limits
- `reflex` - trigger maps for live adaptation
- `composition` - clause insertion/substitution rules

---

## 🚀 Flowstate Scheduling Application

### 1. Flowstate Contract Layer (User Trust + Predictability)

**Goal:** Represent scheduling behavior as ClauseLang clauses users can inspect.

**Example Clauses:**
```swift
// User-facing clauses (Ricardian prose)
"When I'm in deep work mode, don't schedule meetings."
"After 90 minutes of focused work, insert a 10-minute recovery block."
"If a calendar conflict is detected, resolve with minimal disruption."

// Machine-executable form
"WHEN user.focus_mode == 'deep' THEN block_meetings"
"WHEN focused_duration > 90 THEN insert_recovery_block(duration=10)"
"WHEN calendar_conflict_detected == true THEN resolve_conflict(minimal=true)"
```

**Implementation:**
- Store user preferences as ClauseLang clauses
- Render both prose and machine form
- Show "why this suggestion" panel with clauses used

---

### 2. Flow-Cost Objective (Reduce Context Switching)

**Goal:** Model "switch cost" as first-class constraint.

**ClauseLang Clauses:**
```swift
// Penalize task fragmentation
"WHEN task_count > 3 AND block_duration < 30 THEN penalize_fragmentation(penalty=high)"

// Cluster by cognitive mode
"WHEN cognitive_mode == 'creative' THEN cluster_creative_tasks"
"WHEN cognitive_mode == 'admin' THEN cluster_admin_tasks"

// Enforce minimum block sizes
"WHEN focus_mode == 'deep' AND block_duration < 45 THEN reject_block"
```

**Implementation:**
- Add `flow_cost` to scheduling constraints
- Use clauses to enforce clustering rules
- Apply penalties in optimization objective

---

### 3. Reflexive Scheduling (Live Adaptation)

**Goal:** Use reflex triggers to adapt without chaos.

**Reflex Triggers:**
```swift
reflex: {
    trigger_map: {
        "user_edits_block": "learn_preference_clause",
        "calendar_conflict_detected": "resolve_conflict_clause",
        "focus_break_detected": "insert_recovery_block_clause"
    }
}
```

**Example KO:**
```swift
{
    "clause_id": "flowstate.session.plan.v1",
    "type": "orchestration",
    "dag_nodes": [
        { "id": "ingest", "clause": "WHEN notes_count > 0 THEN normalize_fragments" },
        { "id": "cluster", "clause": "WHEN normalized_ready == true THEN cluster_by_intent" },
        { "id": "prioritize", "clause": "WHEN clusters_ready == true THEN rank_by_flow_cost" },
        { "id": "allocate", "clause": "WHEN ranked_ready == true THEN allocate_time_blocks" },
        { "id": "commit", "clause": "WHEN schedule_valid == true THEN write_calendar_draft" }
    ],
    "reflex": {
        "trigger_map": {
            "calendar_conflict_detected": "resolve_conflict_clause",
            "user_edits_block": "learn_preference_clause",
            "focus_break_detected": "insert_recovery_block_clause"
        }
    }
}
```

**Implementation:**
- Event-driven reflex triggers
- Local adaptation (don't reshuffle entire day)
- Learn from user edits

---

### 4. Entropy Caps (Avoid Over-Optimization)

**Goal:** Prevent continuous auto-editing that kills flow.

**ClauseLang:**
```swift
loop: {
    bounds: 6,
    entropy.cap: 0.22,
    retry.limit: 2,
    exit_conditions: ["schedule_valid == true", "user_cancelled == true"]
}
```

**Implementation:**
- Track rescheduling churn
- Freeze plan if entropy exceeds cap
- Ask for single decision instead of continuous edits

---

### 5. Governance & Ethics-as-Product-Feature

**Goal:** Make governance legible in-product.

**Product Features:**
- **"Why This Suggestion" Panel**: Shows clauses used, inputs, what wasn't used
- **Consent + Revocation Flow**: Real effects (stop learning, delete embeddings)
- **Public Policy Page**: Versioned "Consensus Canvas" style policy tradeoffs

**ClauseLang Clauses:**
```swift
// Consent management
"WHEN consent_revoked == true THEN notify AND log AND revoke_access AND archive_data"

// Learning controls
"WHEN learning_disabled == true THEN stop_pattern_extraction"
"WHEN data_deletion_requested == true THEN delete_embeddings AND clear_knowledge_graph"
```

---

### 6. Agent Contract Primitives for Core Features

**Actors:**
- `user` - The human user
- `scheduler_agent` - The scheduling AI
- `notification_daemon` - Background notifications
- `audit_bot` - Audit trail maintenance

**Time-Based:**
```swift
"WHEN block_duration > 120 THEN suggest_break"
"WHEN tentative_plan_age > 24_hours THEN expire_plan"
```

**Role-Based:**
```swift
"WHEN actor == 'scheduler_agent' AND action == 'write_calendar' THEN require_user_approval"
"WHEN actor == 'user' THEN allow_all_actions"
```

**Violation Triggers:**
```swift
"WHEN consent_revoked == true THEN notify AND log AND revoke_access"
"WHEN policy_violation == true THEN block_action AND notify_user"
```

---

## 📋 Implementation Phases

### Phase 1: Core ClauseLang Infrastructure ✅

**Status:** Partially complete, needs refinement

**Tasks:**
1. ✅ Basic ClauseLang types (needs KO structure)
2. ✅ Simple parser (needs DAG composition)
3. ⏳ Add KO (Kernel Object) structure
4. ⏳ Add operad collapse logic
5. ⏳ Add reflex trigger system

---

### Phase 2: Flowstate Contract Layer 🔄

**Goal:** User-facing clauses for scheduling behavior.

**Tasks:**
1. ⏳ Create Flowstate Clause Library:
   - Focus blocks
   - Recovery blocks
   - Meeting shields
   - Errands batching
2. ⏳ Ricardian rendering (prose + machine form)
3. ⏳ "Why this suggestion" panel
4. ⏳ User preference clauses

---

### Phase 3: DAG Composition & KO Compiler 🔄

**Goal:** Build DAG from clauses, collapse to executable KO.

**Tasks:**
1. ⏳ DAG builder from clause dependencies
2. ⏳ Operad collapse (compose → single KO)
3. ⏳ Execution order canonicalization
4. ⏳ Event table generation

**Pipeline:**
```
Parse (PEG) → AST
Type-check + Validate → Clause IR
Build DAG (yields/inputs + dag_nodes)
Compose (substitute/insert clauses)
Collapse → Single KO (canonical execution order + event table)
Runtime → Execute KO, emit events, apply reflex + loop controls
```

---

### Phase 4: Reflexive Scheduling 🔄

**Goal:** Live adaptation with reflex triggers.

**Tasks:**
1. ⏳ Reflex trigger system
2. ⏳ Event-driven clause activation
3. ⏳ Local adaptation (don't reshuffle entire day)
4. ⏳ Preference learning from edits

---

### Phase 5: Entropy Caps & Flow-Cost 🔄

**Goal:** Prevent over-optimization, reduce context switching.

**Tasks:**
1. ⏳ Entropy tracking
2. ⏳ Flow-cost objective
3. ⏳ Clustering by cognitive mode
4. ⏳ Minimum block size enforcement

---

### Phase 6: Governance & Ethics 🔄

**Goal:** Legible governance in-product.

**Tasks:**
1. ⏳ Consent + revocation flows
2. ⏳ Audit trail with clauses
3. ⏳ Policy transparency UI
4. ⏳ Data deletion workflows

---

## 🎯 Key Architectural Changes Needed

### 1. KO Structure (Kernel Object)

```swift
public struct KernelObject: Codable {
    public let clauseId: String
    public let type: OrchestrationType
    public let role: SemanticRole
    public let inputs: [String]
    public let yields: [String]
    public let dagNodes: [DAGNode]
    public let logic: ClauseLogic
    public let loop: LoopControl?
    public let reflex: ReflexTriggers?
    public let composition: [CompositionRule]?
    public let metadata: KernelMetadata
}
```

### 2. DAG Composition

```swift
public struct DAGNode: Codable {
    public let id: String
    public let clause: Clause
    public let dependencies: [String]
    public let inputs: [String]
    public let outputs: [String]
}
```

### 3. Reflex Triggers

```swift
public struct ReflexTriggers: Codable {
    public let triggerMap: [String: String] // event -> clause_id
    public let entropyHint: Double?
    public let kernel: String?
}
```

### 4. Loop Control

```swift
public struct LoopControl: Codable {
    public let bounds: Int
    public let entropyCap: Double?
    public let retryLimit: Int
    public let retryScope: String
    public let exitConditions: [String]
}
```

---

## 📊 Integration with Existing Systems

### WorkflowWarmer Integration

**Current:** Hardcoded workflow patterns  
**Proposed:** Load workflow patterns as ClauseLang KOs

```swift
// Instead of hardcoded Swift:
case .scheduling:
    steps.append(DeterministicStep(...))

// Use ClauseLang KO:
let schedulingKO = try await clauseLangStorage.loadKO(id: "scheduling_workflow_v1")
let warmedWorkflow = await workflowWarmer.warmFromKO(schedulingKO)
```

### ReasoningEngine Integration

**Current:** Policy enforcement  
**Proposed:** Execute ClauseLang KOs as workflow orchestrator

```swift
// Execute KO as workflow
let result = try await reasoningEngine.executeKO(
    ko: schedulingKO,
    context: reasoningContext
)
```

### SchedulingReasoner Integration

**Current:** Heuristic scheduling  
**Proposed:** ClauseLang-driven scheduling with flow-cost

```swift
// Use ClauseLang clauses for scheduling constraints
let schedulingKO = buildSchedulingKO(
    clauses: flowCostClauses + focusModeClauses + recoveryClauses
)
let schedule = try await schedulingReasoner.optimize(ko: schedulingKO)
```

---

## ✅ Next Immediate Steps

1. **Add KO Structure** - Implement KernelObject types
2. **DAG Builder** - Build DAG from clause dependencies
3. **Operad Collapse** - Compose clauses into single executable KO
4. **Flowstate Clause Library** - Starter clauses for scheduling
5. **Reflex System** - Event-driven clause activation

---

**Status:** Ready to implement with refined understanding! 🎯
