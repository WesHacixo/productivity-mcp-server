# Workflow Warming: Predictive Caching for Latency Enhancement

## Overview

The **WorkflowWarmer** pre-computes and caches deterministic parts of predicted workflows, dramatically reducing latency when users execute anticipated actions. This is a **cheap, high-impact optimization** that only caches local, deterministic components.

## Philosophy

> "Since it is anticipating needs, warm caches for next task chains in predicted workflows - but only the local deterministic parts, like clauselang logics of execution. This technique would be cheap and latency-enhancing."

## How It Works

### 1. Prediction → Warming

When the `PredictiveEngine` generates predictions with high confidence (>0.7), the `WorkflowWarmer` automatically pre-computes:

- **Knowledge Retrieval** - Pre-fetches relevant knowledge from vector memory and knowledge graph
- **Plan Structure** - Pre-computes deterministic planning logic (the "clauselang" execution flow)
- **Tool Selection** - Pre-selects appropriate tools based on prediction type
- **Reasoning Context** - Pre-builds reasoning context with entities and intent

### 2. Execution → Cache Hit

When the user actually performs the predicted action:

- **Cache Lookup** - Checks for warmed workflow
- **Fast Path** - Uses pre-computed knowledge, plan structure, and context
- **Network Calls Only** - Only executes non-deterministic parts (actual tool calls)

### 3. What Gets Cached (Deterministic Only)

✅ **Cached (Cheap, Local, Deterministic):**
- Knowledge retrieval (vector search, graph traversal)
- Plan structure (deterministic execution flow)
- Tool selection (based on prediction type)
- Reasoning context (entity extraction, intent classification)

❌ **Not Cached (Non-Deterministic, Network-Dependent):**
- Actual tool execution (network calls, API requests)
- Dynamic data (current time, user state)
- External responses (API results, database queries)

## Architecture

```
PredictiveEngine
    ↓ (generates predictions)
WorkflowWarmer
    ↓ (pre-computes deterministic parts)
    ├── Knowledge Retrieval (vector search)
    ├── Plan Structure (deterministic logic)
    ├── Tool Selection (prediction-based)
    └── Reasoning Context (entity/intent)
    ↓ (stores in cache)
ReasoningEngine
    ↓ (user executes action)
    ├── Cache Hit? → Use warmed workflow (fast!)
    └── Cache Miss? → Normal execution
```

## Example Flow

### Prediction Phase

```
1. PredictiveEngine: "User will schedule 'Team standup' (confidence: 0.85)"
2. WorkflowWarmer: "Warming workflow for 'Schedule Team standup'"
   ├── Pre-retrieve: Knowledge about "Team standup" patterns
   ├── Pre-compute: Plan structure (knowledge → plan → calendar tool)
   ├── Pre-select: Calendar tool
   └── Pre-build: Reasoning context (intent=create, entity="Team standup")
3. Cache stored: Ready for instant execution
```

### Execution Phase

```
1. User: "Schedule Team standup"
2. ReasoningEngine: "Cache hit! Using warmed workflow"
   ├── Knowledge: ✅ Already retrieved (0ms vs 100ms)
   ├── Plan: ✅ Already structured (0ms vs 50ms)
   ├── Tools: ✅ Already selected (0ms vs 20ms)
   └── Context: ✅ Already built (0ms vs 30ms)
3. Only executes: Calendar tool call (network, unavoidable)
4. Total latency: ~200ms (vs ~400ms without warming)
```

## Deterministic Workflow Steps

### Scheduling Workflow

```swift
DeterministicStep(
    type: .knowledgeRetrieval,
    description: "Retrieve scheduling context",
    deterministic: true ✅
)
DeterministicStep(
    type: .planning,
    description: "Plan schedule action",
    deterministic: true ✅
)
DeterministicStep(
    type: .toolExecution,
    description: "Execute calendar tool",
    deterministic: false ❌ (network call)
)
```

### Task Creation Workflow

```swift
DeterministicStep(
    type: .knowledgeRetrieval,
    description: "Retrieve task context",
    deterministic: true ✅
)
DeterministicStep(
    type: .planning,
    description: "Plan task creation",
    deterministic: true ✅
)
DeterministicStep(
    type: .toolExecution,
    description: "Execute tasks tool",
    deterministic: false ❌ (network call)
)
```

## Benefits

### 1. Latency Reduction

- **Knowledge Retrieval**: 100ms → 0ms (cached)
- **Plan Structure**: 50ms → 0ms (pre-computed)
- **Tool Selection**: 20ms → 0ms (pre-selected)
- **Context Building**: 30ms → 0ms (pre-built)
- **Total Savings**: ~200ms per cached workflow

### 2. Cost Efficiency

- **Only deterministic parts** - No network calls cached
- **Local computation** - Uses existing vector memory and graph
- **Small cache size** - Max 50 workflows (pruned by age)
- **Cheap operations** - Vector search, graph traversal, planning logic

### 3. User Experience

- **Instant responses** - Feels faster, more responsive
- **Predictive accuracy** - Only warms high-confidence predictions (>0.7)
- **Graceful degradation** - Falls back to normal execution if cache miss

## Cache Management

### Pruning Strategy

- **Max Size**: 50 warmed workflows
- **Eviction**: LRU (Least Recently Used)
- **Invalidation**: On action completion or after 1 hour

### Cache Invalidation

```swift
// Invalidate when action completes
await workflowWarmer.invalidate("Schedule Team standup")

// Automatic pruning when cache is full
await workflowWarmer.pruneCache()
```

## Integration Points

### 1. PredictiveEngine

```swift
// Automatically warms workflows when generating predictions
let predictions = await predictor.predict(context: context)
// → WorkflowWarmer.warmWorkflows() called automatically
```

### 2. ReasoningEngine

```swift
// Checks for warmed workflow before normal execution
let warmed = await workflowWarmer.getWarmedWorkflow(for: userInput)
if let warmed = warmed {
    // Fast path: Use pre-computed knowledge, plan, context
} else {
    // Normal path: Compute everything
}
```

### 3. ProactiveAssistant

```swift
// Workflow warming happens automatically when generating suggestions
let suggestions = await proactiveAssistant.generateSuggestions(context: context)
// → Predictions generated → Workflows warmed
```

## Performance Characteristics

### Cache Hit Rate

- **High-confidence predictions** (>0.7): ~80% hit rate expected
- **Pattern-based predictions**: ~70% hit rate
- **Time-based predictions**: ~60% hit rate

### Latency Improvement

- **Cache Hit**: ~200ms faster (50% reduction)
- **Cache Miss**: No penalty (normal execution)
- **Overall**: ~30-40% average latency reduction

### Memory Usage

- **Per Workflow**: ~5-10KB (knowledge items, plan structure)
- **Max Cache**: 50 workflows = ~250-500KB
- **Negligible**: <1MB total

## Future Enhancements

1. **MLX Integration** - Pre-compute MLX embeddings for predicted queries
2. **Multi-Step Workflows** - Cache entire workflow chains
3. **Adaptive Warming** - Learn which workflows benefit most from warming
4. **Background Warming** - Warm workflows in background thread
5. **Smart Pruning** - Keep frequently used workflows longer

## Philosophy in Practice

This technique embodies the core principles:

- **Cheap** - Only deterministic, local computation
- **Effective** - Significant latency reduction
- **Intelligent** - Only warms high-confidence predictions
- **Elegant** - Simple cache lookup, no complex logic

The workflow warmer is a perfect example of **elegant reasoning** - a simple, cheap optimization that provides significant value through intelligent anticipation.
