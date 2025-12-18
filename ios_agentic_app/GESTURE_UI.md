# Gesture-Driven UI Architecture

## Philosophy

> "Simple, silent, adapting to context; user gestures alter the visual space."

The UI is designed to **remove cognitive load** through intuitive gestures and context-adaptive behavior. Every interaction is silent, elegant, and responds naturally to user intent.

## Core Principles

1. **Silent Operation** - No unnecessary confirmations or interruptions
2. **Context Adaptation** - UI adapts to user's schedule and preferences
3. **Gesture-Driven** - Visual space responds to natural gestures
4. **Zero Cognitive Load** - User doesn't think about how to interact

## Gesture Interactions

### Timeline View

#### Tap Gestures
- **Tap empty slot** → Quick schedule overlay appears
- **Tap event** → Expands to show details and actions
- **Tap time label** → Focuses that time slot (context adaptation)

#### Drag Gestures
- **Drag event vertically** → Reschedules to new time
- **Swipe left/right on date** → Navigate days (or use chevrons)

#### Long Press
- **Long press event** → Shows quick actions menu

#### Visual Adaptations
- **Focused time slot** → Subtle highlight appears
- **Expanded events** → Show full details and actions
- **Context summary** → Updates based on selected date
- **Available time** → Calculated and displayed automatically

### Tasks View

#### Swipe Gestures
- **Swipe right** → Quick schedule (adds to calendar)
- **Swipe left** → Delete task
- **Swipe to complete** → Toggle completion (tap circle)

#### Drag Gestures
- **Drag to reorder** → Reorder tasks by priority

#### Tap Gestures
- **Tap task** → Opens detail view
- **Tap filter chip** → Filters with animation

#### Visual Adaptations
- **Filter chips** → Show counts, highlight selected
- **Overdue tasks** → Red time indicator
- **Completed tasks** → Grayed out, strikethrough
- **Swipe indicators** → Appear during swipe gesture

## Context-Adaptive Features

### Timeline Context
- **Date selection** → Automatically loads events for that date
- **Time slot focus** → Highlights available time
- **Event density** → Shows summary of events and free time
- **Quick schedule** → Pre-fills with focused time slot

### Task Context
- **Filter counts** → Shows number of tasks per filter
- **Overdue highlighting** → Red indicators for urgency
- **Completion state** → Visual feedback on toggle
- **Scheduling integration** → Swipe to schedule uses scheduling reasoner

## Quick Actions

### Timeline Quick Schedule
1. Tap empty time slot OR tap + button
2. Overlay appears with text field
3. Type natural language: "Meeting with John at 2pm"
4. System handles all complexity (conflicts, optimization)
5. Event appears silently

### Task Quick Add
1. Tap + button
2. Type task description
3. System creates and optionally schedules
4. Task appears in list

### Swipe Actions
- **Right swipe on task** → "Schedule this"
- **Left swipe on task** → "Delete this"
- **Drag event** → "Move to this time"

## Visual Space Adaptations

### Dynamic Layouts
- **Expanded events** → Show more information
- **Focused slots** → Highlight with subtle background
- **Filter changes** → Animate list updates
- **Swipe gestures** → Reveal action buttons

### Context Indicators
- **Time availability** → "X hours free" in header
- **Event counts** → "Y events" summary
- **Filter counts** → "(N)" in filter chips
- **Overdue warnings** → Red time indicators

### Silent Feedback
- **Animations** → Smooth transitions, no sound
- **Color changes** → Subtle highlights, no alerts
- **State updates** → Immediate visual feedback
- **No confirmations** → Actions happen immediately

## Integration with Scheduling Reasoner

All scheduling interactions use the `SchedulingReasoner`:

```swift
// Natural language scheduling
"Schedule meeting with John tomorrow at 2pm"
→ SchedulingReasoner handles:
  - Intent understanding
  - Conflict detection
  - Time optimization
  - Natural response

// Quick schedule from gesture
Tap empty slot → Type "Meeting" → Schedule
→ System finds optimal time automatically

// Reschedule from drag
Drag event → New time calculated
→ System checks conflicts and adjusts
```

## User Experience Flow

### Scheduling a Meeting
1. **User**: Taps empty 2pm slot
2. **UI**: Overlay appears, pre-filled with "2pm"
3. **User**: Types "Meeting with John"
4. **System**: Schedules, checks conflicts, optimizes
5. **UI**: Event appears silently at optimal time
6. **User**: Sees result, no cognitive load

### Completing a Task
1. **User**: Swipes right on task (or taps circle)
2. **UI**: Task animates to completed state
3. **System**: Updates backend silently
4. **User**: Sees visual feedback, continues working

### Rescheduling an Event
1. **User**: Drags event to new time
2. **UI**: Shows preview of new time
3. **System**: Checks conflicts, suggests alternatives if needed
4. **UI**: Event moves to new time, or shows conflict resolution
5. **User**: Sees result, no manual conflict resolution needed

## Technical Implementation

### Gesture Recognition
- SwiftUI native gestures (DragGesture, TapGesture)
- Custom gesture handlers for swipe actions
- State management for gesture feedback

### Context Management
- `@State` for UI state (focused slots, expanded events)
- `@StateObject` for view models (scheduling, tasks)
- Context-adaptive calculations (available time, event counts)

### Animation
- SwiftUI animations for state changes
- Smooth transitions for layout updates
- Gesture feedback animations

### Integration
- SchedulingReasoner for all scheduling
- MCP server for data persistence
- MLX for intelligent scheduling decisions

## Future Enhancements

1. **Haptic Feedback** - Subtle vibrations for gesture confirmation
2. **Voice Gestures** - "Schedule this" voice command
3. **Multi-Touch** - Pinch to zoom timeline, two-finger drag
4. **Predictive Gestures** - System learns user patterns
5. **Contextual Menus** - Long-press for more options
6. **Gesture Customization** - User can customize gesture actions

## Philosophy in Practice

Every interaction follows the core principles:

- **Simple** - One gesture, one action
- **Silent** - No confirmations, no interruptions
- **Adaptive** - UI responds to context automatically
- **Gesture-Driven** - Visual space changes with gestures

The user never thinks about *how* to interact - they just do what feels natural, and the system handles the complexity.
