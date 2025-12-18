# ClauseLang Integration: Flowstate Scheduling with Contractual Logic

## Overview

ClauseLang is now integrated into the iOS app, providing a **minimal execution-oriented clause DSL** that bridges human intent with machine execution. It enables **predictable, reflexive scheduling** with flow-cost optimization and entropy control.

## Core Concept

> "A clause is a compact conditional rule: WHEN <condition> THEN <action>"

ClauseLang sits between:
- **Human intent** (prose, notes, "do X when Y")
- **Machine execution** (validated schemas, DAG plans, triggers, retries)

## Architecture

```
Human Intent (prose)
    ↓
ClauseLang Parser (WHEN/THEN → AST)
    ↓
Clause Validation (Zod/JSON Schema)
    ↓
Flowstate Scheduler (executes clauses)
    ↓
Machine Execution (DAG, triggers, retries)
```

## Components

### 1. ClauseLang Parser (`Sources/ClauseLang/ClauseLang.swift`)

**Syntax:**
```
WHEN <condition> THEN <action>
```

**Operators:** `==`, `!=`, `>`, `<`, `>=`, `<=`

**Values:** `true`/`false`, `"strings"`, numbers, identifiers

**Example:**
```
WHEN user.focus_mode == "deep" THEN set(block.min_duration_minutes, 45)
WHEN notes_count > 0 THEN normalize_fragments
WHEN calendar_conflict_detected == true THEN resolve_conflict_clause
```

**Features:**
- Parses clauses to AST
- Evaluates conditions against context
- Executes actions (set variables, trigger events)
- Type-safe value resolution

### 2. Flowstate Scheduler (`Sources/ClauseLang/FlowstateScheduler.swift`)

**Flow-Cost Optimization:**
- Clusters tasks by cognitive mode (deep/shallow/social)
- Ranks by flow cost (minimizes context switching)
- Allocates time blocks with minimum duration
- Calculates total flow cost

**Entropy Caps:**
- Tracks schedule churn (entropy accumulator)
- Freezes schedule when cap reached (0.22)
- Requires user approval before continuing

**Reflexive Scheduling:**
- Handles triggers: conflicts, user edits, focus breaks
- Executes reflex clauses automatically
- Adapts without chaos (minimal disruption)

**Example Flow:**
```
1. User: "Schedule my day"
2. FlowstateScheduler:
   - Executes active contracts
   - Optimizes flow cost (clusters, ranks, allocates)
   - Checks entropy cap
   - Generates schedule
3. Result: Optimized schedule with low context switching
```

### 3. Flowstate Contracts (`Sources/ClauseLang/FlowstateContracts.swift`)

**Default Contracts:**

**Deep Work Contract:**
```
WHEN user.focus_mode == "deep" THEN set(block.min_duration_minutes, 45)
WHEN user.focus_mode == "deep" THEN set(block.context_switch_penalty, high)
```

**Meeting Contract:**
```
WHEN user.focus_mode == "deep" THEN set(block.allow_meetings, false)
WHEN calendar_conflict_detected == true THEN resolve_conflict_clause
```

**Recovery Contract:**
```
WHEN block.duration_minutes >= 90 THEN insert_recovery_block
```

**Entropy Contract:**
```
WHEN entropy >= 0.22 THEN freeze_schedule
```

**Preference Contract:**
```
WHEN user_edits_block == true THEN learn_preference_clause
```

### 4. Clause Inspector (`Sources/UI/ClauseInspectorView.swift`)

**Transparency UI:**
- Shows "why this suggestion" with executed clauses
- Displays human-readable descriptions
- Shows raw ClauseLang (machine-readable)
- Displays flow cost and entropy status

**Governance Features:**
- User can inspect all active contracts
- See which clauses were executed
- Understand flow cost and entropy
- Trust through transparency

## Key Features

### 1. Flow-Cost Optimization

**Problem:** Context switching kills productivity

**Solution:**
- Cluster tasks by cognitive mode
- Rank by flow cost (lower = better)
- Allocate blocks with minimum duration
- Penalize context switching

**Example:**
```
Tasks: [Code review, Email, Meeting, Code review]
→ Clustered: [Code review, Code review] + [Email, Meeting]
→ Flow cost: 0.3 (low - minimal switching)
```

### 2. Entropy Caps

**Problem:** Over-optimization creates chaos

**Solution:**
- Track schedule churn (entropy)
- Cap at 0.22 (from ClauseLang schema)
- Freeze schedule when cap reached
- Require user approval

**Example:**
```
After 3 auto-reschedules: entropy = 0.25
→ Cap reached: "Please review and approve current schedule"
→ User approves: entropy reset to 0.0
```

### 3. Reflexive Scheduling

**Problem:** Static schedules break when reality changes

**Solution:**
- Reflex triggers: conflicts, edits, breaks
- Automatic clause execution
- Minimal disruption (don't reshuffle entire day)

**Example:**
```
Trigger: calendar_conflict_detected
→ Reflex clause: "WHEN calendar_conflict_detected == true THEN resolve_conflict_clause"
→ Action: Resolve conflict, don't reshuffle entire schedule
```

### 4. Governance & Transparency

**Problem:** "Why did the AI schedule this?"

**Solution:**
- Clause Inspector shows executed clauses
- Human-readable descriptions
- Raw ClauseLang for verification
- Flow cost and entropy visible

**Example:**
```
User: "Why did you schedule this?"
→ Clause Inspector shows:
  - "In deep work mode, schedule blocks of at least 45 minutes"
  - Flow cost: 0.15 (low)
  - Entropy: 0.10 (under cap)
```

## Integration Points

### With SchedulingReasoner

```swift
let flowstateScheduler = FlowstateScheduler(
    clauseLang: clauseLang,
    schedulingReasoner: schedulingReasoner
)

let result = try await flowstateScheduler.scheduleWithFlowstate(
    request: "Schedule my day",
    userFlowstate: flowstate,
    constraints: constraints
)
```

### With WorkflowWarmer

ClauseLang clauses are deterministic and can be pre-computed:
- Condition evaluation (deterministic)
- Plan structure (deterministic)
- Flow-cost calculation (deterministic)

### With ProactiveAssistant

Contracts can be suggested based on patterns:
- "You often work in deep focus mode. Enable deep work contract?"
- "You schedule meetings during breaks. Add meeting contract?"

## Example Workflow

### User: "Schedule my day"

1. **Parse Request**
   - Extract tasks, preferences, constraints

2. **Execute Contracts**
   - Deep work contract: "Set min block duration to 45min"
   - Meeting contract: "Don't schedule meetings during deep work"
   - Recovery contract: "Insert recovery after 90min"

3. **Optimize Flow Cost**
   - Cluster: [Deep tasks] + [Shallow tasks] + [Meetings]
   - Rank: Deep first (matches focus mode)
   - Allocate: 45min blocks for deep, 30min for shallow

4. **Check Entropy**
   - Current: 0.10
   - Cap: 0.22
   - ✅ Proceed

5. **Generate Schedule**
   - 9:00-9:45: Deep work (Code review)
   - 9:45-10:00: Recovery
   - 10:00-10:30: Shallow (Email)
   - 10:30-11:00: Meeting

6. **Show Clause Inspector**
   - "Why this suggestion" button
   - Shows executed clauses
   - Shows flow cost: 0.12 (low)

## Philosophy

ClauseLang embodies the core principles:

- **Predictable** - Contracts are explicit and inspectable
- **Reflexive** - Adapts to reality without chaos
- **Transparent** - User can see why decisions were made
- **Governed** - Entropy caps prevent over-optimization
- **Elegant** - Simple syntax, powerful execution

## Future Enhancements

1. **KO Compiler** - Compile clauses to Kernel Objects (executable artifacts)
2. **Operad Collapse** - Compose multiple clauses into single executable
3. **Ricardian Hybrid** - Render prose + machine form for trust
4. **Consent Flow** - User can revoke contracts, delete embeddings
5. **Public Canvas** - Versioned policy tradeoffs, revisable

## Contract Templates

Users can customize contracts:
- "When I'm in deep work, don't schedule meetings"
- "After 90 minutes, insert a 10-minute recovery block"
- "If entropy exceeds 0.2, ask for approval"

These feel like **settings, not legalese** - human-readable contracts that users can understand and trust.

ClauseLang transforms scheduling from "black box AI" to **transparent, contractual logic** that users can inspect, understand, and trust.
