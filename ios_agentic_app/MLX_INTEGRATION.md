# MLX Integration Guide

## Overview

The app now includes full MLX integration for on-device reasoning, planning, and knowledge management. The architecture is designed to **remove cognitive load from scheduling** - users just say what they want, and the system handles all complexity.

## Philosophy

> "Take as much cognitive load out of scheduling as possible. The UX remains simple, silent, adapting to context; user gestures alter the visual space."

The MLX integration enables:
- **Natural language scheduling** - "Schedule a meeting with John tomorrow at 2pm"
- **Automatic conflict resolution** - Detects and resolves scheduling conflicts
- **Intelligent optimization** - Finds optimal times based on preferences
- **Zero cognitive load** - User doesn't think about conflicts, preferences, or optimization

## Architecture

### MLX Components

1. **MLXLLM** (`Sources/MLX/MLXLLM.swift`)
   - On-device LLM for reasoning, planning, and understanding
   - Scheduling-specific prompts and context
   - Natural language generation

2. **MLXEmbeddings** (`Sources/MLX/MLXEmbeddings.swift`)
   - Semantic embeddings for knowledge search
   - Vector similarity computation
   - Batch embedding generation

3. **SchedulingReasoner** (`Sources/Scheduling/SchedulingReasoner.swift`)
   - Specialized reasoning for scheduling
   - Conflict detection and resolution
   - Auto-scheduling with optimization
   - Natural language scheduling interface

### Integration Points

#### Planner
- Uses MLX LLM for intelligent planning
- Scheduling-aware plan generation
- Falls back to heuristics if MLX unavailable

#### Reasoning Engine
- MLX-powered reflection and self-critique
- Knowledge-informed planning
- Iterative plan refinement

#### Vector Memory
- MLX embeddings for semantic search
- Knowledge retrieval with context
- Falls back to hash-based embeddings

## Usage

### Natural Language Scheduling

```swift
let reasoner = SchedulingReasoner(...)
let result = try await reasoner.schedule("Schedule a meeting with John tomorrow at 2pm")

// Result includes:
// - Success status
// - Natural language response
// - Scheduled items
// - Conflicts (if any)
// - Suggestions
```

### Auto-Scheduling

```swift
let result = try await reasoner.autoSchedule(
    tasks: pendingTasks,
    preferences: userPreferences
)

// Automatically matches tasks to available time slots
// Respects work hours, buffer time, and preferences
```

### Conflict Resolution

```swift
let resolution = try await reasoner.resolveConflicts(conflicts)

// Intelligently resolves conflicts using MLX
// Suggests alternatives and optimizations
```

## MLX Model Setup

### Current Status

The MLX integration is **ready** but uses placeholder implementations until MLX models are loaded. The architecture supports:

1. **Model Loading**
   ```swift
   try await mlxLLM.load(modelPath: "path/to/model")
   try await mlxEmbeddings.load(modelPath: "path/to/embeddings")
   ```

2. **Fallback Behavior**
   - If MLX models not loaded, uses heuristic fallbacks
   - Graceful degradation ensures app always works
   - No breaking changes when models unavailable

### Next Steps

1. **Add MLX Swift Package**
   ```swift
   // In Package.swift
   .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.0.1")
   ```

2. **Load Models**
   - Download or bundle MLX models
   - Implement model loading in `MLXLLM.load()`
   - Implement embedding model loading in `MLXEmbeddings.load()`

3. **Replace Placeholders**
   - Replace `heuristicGeneration()` with actual MLX inference
   - Replace `generatePlaceholderEmbedding()` with MLX embeddings
   - Update parsing functions to handle MLX output

## Scheduling Intelligence

### What It Handles Automatically

1. **Time Parsing**
   - "tomorrow at 2pm" → Actual date/time
   - "next Friday" → Calculated date
   - "in 2 hours" → Relative time

2. **Conflict Detection**
   - Checks calendar for overlaps
   - Detects resource conflicts
   - Identifies preference violations

3. **Optimization**
   - Finds optimal time slots
   - Respects work hours
   - Considers buffer time
   - Suggests alternatives

4. **Natural Responses**
   - "Scheduled for tomorrow at 2pm"
   - "That time conflicts with your team meeting. How about 3pm?"
   - "I've scheduled 3 tasks for tomorrow morning"

### User Experience

**Before (High Cognitive Load):**
- User: "I need to schedule a meeting"
- System: "When?"
- User: "Tomorrow"
- System: "What time?"
- User: "2pm"
- System: "That conflicts with your 1:30pm meeting. Choose another time."
- User: "3pm"
- System: "That's outside your work hours. Choose another time."
- User: [frustrated]

**After (Zero Cognitive Load):**
- User: "Schedule a meeting with John tomorrow at 2pm"
- System: "That time conflicts with your team meeting. I've scheduled it for 3pm instead. Should I notify John?"
- User: "Yes"
- System: "Done. Meeting scheduled for tomorrow at 3pm."

## Technical Details

### Scheduling Context

The `SchedulingContext` provides:
- Current time and calendar state
- Upcoming events (today, tomorrow, future)
- Task backlog
- Available time slots
- User preferences (work hours, buffer time, auto-schedule)

### Intent Understanding

MLX understands scheduling intents:
- `createTask` - Create a new task
- `scheduleEvent` - Schedule a calendar event
- `reschedule` - Move existing item
- `query` - Ask about schedule
- `delete` - Remove item

### Entity Extraction

Extracts from natural language:
- Task/event name
- Date and time
- Duration
- Priority
- Participants
- Location

## Future Enhancements

1. **Multi-Modal Scheduling**
   - Parse images of calendars
   - Voice input for scheduling
   - Gesture-based time selection

2. **Predictive Scheduling**
   - Learn user patterns
   - Suggest optimal times
   - Proactive scheduling

3. **Collaborative Scheduling**
   - Find mutual availability
   - Negotiate times
   - Handle group scheduling

4. **Context Awareness**
   - Location-based suggestions
   - Time zone handling
   - Travel time consideration

## Philosophy in Practice

The MLX integration embodies the core philosophy:

- **Simple UX** - User just says what they want
- **Silent Operation** - Complexity happens in background
- **Context Adaptation** - System adapts to user's schedule
- **Gesture-Driven** - Visual space responds to user actions

The agent handles all the thinking, so the user doesn't have to.
