/**
 * Core data models for the Productivity Tool App
 * These types define the structure of tasks, goals, time blocks, and file attachments
 */

export type TaskPriority = 1 | 2 | 3 | 4; // 1=high, 4=low
export type TaskCategory = "work" | "personal" | "health" | "learning";
export type RecurrenceFrequency = "daily" | "weekly" | "monthly" | "yearly";

export interface Subtask {
  id: string;
  title: string;
  completed: boolean;
  createdAt: Date;
}

export interface FileAttachment {
  id: string;
  name: string;
  type: string; // MIME type
  size: number; // bytes
  url: string; // Local or cloud URL
  uploadedAt: Date;
  parsedData?: Record<string, any>;
}

export interface RecurrencePattern {
  frequency: RecurrenceFrequency;
  interval: number; // e.g., every 2 weeks
  endDate?: Date;
  daysOfWeek?: number[]; // 0-6 for weekly
}

export interface Task {
  id: string;
  title: string;
  description: string;
  priority: TaskPriority;
  dueDate: Date;
  estimatedDuration: number; // minutes
  category: TaskCategory;
  completed: boolean;
  completedAt?: Date;
  subtasks: Subtask[];
  attachments: FileAttachment[];
  relatedGoals: string[]; // Goal IDs
  recurring?: RecurrencePattern;
  createdAt: Date;
  updatedAt: Date;
}

export interface Milestone {
  id: string;
  title: string;
  targetDate: Date;
  completed: boolean;
  completedAt?: Date;
}

export interface Goal {
  id: string;
  title: string;
  description: string;
  startDate: Date;
  targetDate: Date;
  progress: number; // 0-100
  milestones: Milestone[];
  relatedTasks: string[]; // Task IDs
  archived: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface TimeBlock {
  id: string;
  taskId: string;
  startTime: Date;
  endTime: Date;
  category: TaskCategory;
  actualDuration?: number; // minutes
  completed: boolean;
  completedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export interface InboxFile {
  id: string;
  name: string;
  type: string; // MIME type
  size: number; // bytes
  url: string; // Local file URI
  receivedAt: Date;
  processingStatus: "pending" | "processing" | "parsed" | "error";
  errorMessage?: string;
  preview?: string; // Base64 preview for images
}

export interface AppSettings {
  theme: "light" | "dark" | "auto";
  notificationsEnabled: boolean;
  soundEnabled: boolean;
  hapticFeedbackEnabled: boolean;
  defaultTaskCategory: TaskCategory;
  defaultTaskPriority: TaskPriority;
  workHoursStart: number; // 0-23
  workHoursEnd: number; // 0-23
}

export interface AppState {
  tasks: Task[];
  goals: Goal[];
  timeBlocks: TimeBlock[];
  inboxFiles: InboxFile[];
  settings: AppSettings;
  lastSyncTime?: Date;
}

// Storage keys for AsyncStorage
export const STORAGE_KEYS = {
  TASKS: "@productivity_app/tasks",
  GOALS: "@productivity_app/goals",
  TIME_BLOCKS: "@productivity_app/time_blocks",
  INBOX_FILES: "@productivity_app/inbox_files",
  SETTINGS: "@productivity_app/settings",
} as const;

// Default settings
export const DEFAULT_SETTINGS: AppSettings = {
  theme: "auto",
  notificationsEnabled: true,
  soundEnabled: true,
  hapticFeedbackEnabled: true,
  defaultTaskCategory: "work",
  defaultTaskPriority: 2,
  workHoursStart: 9,
  workHoursEnd: 17,
};
