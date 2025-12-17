# Productivity Tool App - Design Document

## Overview

A personal productivity tool optimized for iOS 17 Pro that combines task management, time planning, and goal tracking with advanced file ingestion capabilities via the share sheet. The app emphasizes one-handed usage and follows Apple Human Interface Guidelines.

---

## Screen List

### Core Screens

1. **Home Dashboard** — Overview of today's tasks, active goals, and time allocation
2. **Tasks Tab** — List-based task management with filtering and sorting
3. **Time Planning Tab** — Calendar and time block visualization
4. **Goals Tab** — Long-term goal tracking with progress indicators
5. **Task Detail Screen** — Full task editing with metadata, subtasks, and file attachments
6. **Goal Detail Screen** — Goal progress, milestones, and related tasks
7. **File Inbox** — Received files from share sheet awaiting processing
8. **Settings Screen** — App configuration, data export, and preferences

### Modal Screens

- **New Task Sheet** — Quick task creation with voice input support
- **New Goal Sheet** — Goal setup with timeline and metrics
- **File Parser Sheet** — Preview and configure file parsing rules
- **Time Block Editor** — Drag-and-drop time scheduling

---

## Primary Content and Functionality

### Home Dashboard

**Content:**
- Today's task count and completion percentage (ring progress indicator)
- Next scheduled time block with countdown timer
- Active goals with milestone progress
- Quick action buttons (Add Task, Start Timer, Log File)

**Functionality:**
- Tap task to navigate to detail
- Tap goal to navigate to detail
- Swipe to complete task
- Long-press to delete or reschedule

### Tasks Tab

**Content:**
- Segmented control: All / Today / Overdue / Completed
- List of tasks with priority color indicators (red/orange/yellow/blue)
- Task title, due date, estimated time, and attachment count
- Search and filter options

**Functionality:**
- Tap to open task detail
- Swipe left to complete/archive
- Swipe right to snooze
- Pull-to-refresh to sync
- Add new task via floating action button

### Time Planning Tab

**Content:**
- Weekly calendar view with time blocks
- Color-coded blocks by task category (work/personal/health/learning)
- Current time indicator
- Estimated vs. actual time comparison

**Functionality:**
- Tap time block to edit
- Drag to reschedule
- Pinch to zoom into day view
- Double-tap to create new block

### Goals Tab

**Content:**
- Goal cards with progress rings (0-100%)
- Goal title, description, target date
- Milestone list with checkmarks
- Related task count

**Functionality:**
- Tap to open goal detail
- Swipe to archive completed goals
- Add new goal via floating action button

### Task Detail Screen

**Content:**
- Task title and description (rich text)
- Priority selector (1-4)
- Due date and time picker
- Estimated duration (hours/minutes)
- Category selector (work/personal/health/learning)
- Subtasks list with checkboxes
- Attached files with file type icons
- Related goals dropdown
- Notes section

**Functionality:**
- Edit all fields inline
- Add/remove subtasks
- Upload files from camera roll or share sheet
- Delete or duplicate task
- Set recurring pattern

### Goal Detail Screen

**Content:**
- Goal title and description
- Progress ring with percentage
- Start date and target date
- Milestone list with due dates
- Related tasks count
- Notes and reflections

**Functionality:**
- Edit goal details
- Add/complete milestones
- View related tasks
- Archive or delete goal

### File Inbox

**Content:**
- Incoming files from share sheet (PDF, images, documents, audio)
- File type icon, name, size, and received time
- Processing status (pending/processing/parsed)
- Preview thumbnail for images

**Functionality:**
- Tap to preview file
- Swipe to delete
- Long-press to assign to task/goal
- Auto-parse with configurable rules

### Settings Screen

**Content:**
- Theme toggle (light/dark/auto)
- Notification preferences
- Data backup and export options
- About section with version info

**Functionality:**
- Toggle notifications
- Export data as JSON/CSV
- Clear app data
- View privacy policy

---

## Key User Flows

### Flow 1: Create and Track a Task

1. User taps **+** button on Home or Tasks tab
2. **New Task Sheet** appears
3. User enters task title, selects priority, sets due date
4. User optionally adds subtasks and attaches files
5. User taps **Save**
6. Task appears in Tasks list and on Home dashboard
7. User can swipe to complete or tap to edit

### Flow 2: Receive File and Link to Task

1. User receives file via share sheet (PDF, image, document)
2. App captures file in **File Inbox**
3. User taps file to preview
4. User selects **Link to Task** option
5. Task picker appears; user selects or creates task
6. File is attached to task and removed from inbox

### Flow 3: Plan Time Blocks

1. User navigates to **Time Planning** tab
2. User taps empty time slot or taps **+** button
3. **Time Block Editor** sheet appears
4. User selects task, sets duration, and confirms
5. Block appears on calendar
6. User can drag to reschedule or tap to edit

### Flow 4: Track Goal Progress

1. User creates goal from **Goals** tab
2. User adds milestones with target dates
3. User links tasks to goal
4. As tasks complete, goal progress updates
5. User can view goal detail to see milestone status

### Flow 5: Parse and Ingest File Data

1. User receives structured file (CSV, JSON, PDF with tables)
2. File appears in **File Inbox**
3. User taps file and selects **Parse Data**
4. **File Parser Sheet** shows preview of parsed data
5. User confirms parsing rules (e.g., "First column = task title")
6. Data is imported as tasks or time blocks

---

## Color Choices

### Brand Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#0A7EA4` | Accent, buttons, active states |
| **Success Green** | `#34C759` | Completed tasks, goal milestones |
| **Warning Orange** | `#FF9500` | Medium priority, upcoming deadlines |
| **Danger Red** | `#FF3B30` | High priority, overdue tasks |
| **Neutral Gray** | `#8E8E93` | Secondary text, disabled states |

### Surface Colors

| Color | Light | Dark |
|-------|-------|------|
| **Background** | `#FFFFFF` | `#000000` |
| **Card Surface** | `#F2F2F7` | `#1C1C1E` |
| **Elevated Surface** | `#FFFFFF` | `#2C2C2E` |

### Category Colors (for tasks and time blocks)

- **Work**: `#0A7EA4` (Primary Blue)
- **Personal**: `#AF52DE` (Purple)
- **Health**: `#34C759` (Green)
- **Learning**: `#FF9500` (Orange)

---

## Typography

- **Title (32pt)**: App headers, screen titles
- **Subtitle (20pt)**: Section headers, card titles
- **Body (16pt)**: Primary content, task descriptions
- **Caption (12pt)**: Secondary text, timestamps, file sizes
- **Line Height**: 1.4× font size minimum for readability

---

## Layout & Spacing

- **Grid**: 8pt base unit (8, 16, 24, 32, 40px spacing)
- **Corner Radius**: 12pt for cards, 8pt for buttons, 16pt for sheets
- **Touch Targets**: Minimum 44pt × 44pt
- **Safe Area**: Respected on all devices with notches/home indicators

---

## Navigation Structure

```
TabNavigator
├── Home (Dashboard)
├── Tasks
│   └── Task Detail (modal)
├── Time Planning
│   └── Time Block Editor (sheet)
├── Goals
│   └── Goal Detail (modal)
├── File Inbox
│   └── File Preview (modal)
└── Settings
```

---

## iOS 17 Pro Optimizations

- **Dynamic Island**: Display timer or current task info
- **Lock Screen Widgets**: Show today's task count and next goal milestone
- **Action Button**: Quick task creation or timer start
- **Gesture Support**: Swipe, long-press, drag-and-drop
- **Haptic Feedback**: Confirm task completion, time block scheduling
- **Accessibility**: VoiceOver support, text scaling, high contrast mode

---

## ACP/MCP Compatibility

- **File Parsing**: Use MCP servers to parse complex file formats (CSV, JSON, PDF tables)
- **Data Export**: Export task/goal data via MCP for integration with external tools
- **Voice Input**: Leverage ACP for voice-to-text task creation
- **Notifications**: Integrate with system notification center via ACP

---

## Data Model

### Task

```typescript
{
  id: string;
  title: string;
  description: string;
  priority: 1 | 2 | 3 | 4; // 1=high, 4=low
  dueDate: Date;
  estimatedDuration: number; // minutes
  category: "work" | "personal" | "health" | "learning";
  completed: boolean;
  subtasks: Subtask[];
  attachments: FileAttachment[];
  relatedGoals: string[]; // Goal IDs
  recurring?: RecurrencePattern;
  createdAt: Date;
  updatedAt: Date;
}
```

### Goal

```typescript
{
  id: string;
  title: string;
  description: string;
  startDate: Date;
  targetDate: Date;
  progress: number; // 0-100
  milestones: Milestone[];
  relatedTasks: string[]; // Task IDs
  createdAt: Date;
  updatedAt: Date;
}
```

### TimeBlock

```typescript
{
  id: string;
  taskId: string;
  startTime: Date;
  endTime: Date;
  category: "work" | "personal" | "health" | "learning";
  actualDuration?: number; // minutes
  completed: boolean;
}
```

### FileAttachment

```typescript
{
  id: string;
  name: string;
  type: string; // MIME type
  size: number; // bytes
  url: string; // Local or cloud URL
  uploadedAt: Date;
  parsedData?: any; // Extracted data from file
}
```

---

## Performance Considerations

- **Lazy Loading**: Load tasks/goals on-demand with pagination
- **Caching**: Cache parsed files locally to avoid re-parsing
- **Background Sync**: Sync data in background when connected
- **Animations**: Use GPU-accelerated transforms for smooth scrolling
- **Memory**: Limit in-memory task list to 500 items; paginate beyond

---

## Accessibility

- All interactive elements labeled for VoiceOver
- Minimum text size 14pt for body content
- Color not the only indicator of priority (use icons/badges)
- High contrast mode support
- Keyboard navigation for all screens

