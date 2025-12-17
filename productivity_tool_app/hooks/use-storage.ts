/**
 * Custom hooks for AsyncStorage persistence
 * Provides type-safe storage operations for tasks, goals, and other app data
 */

import AsyncStorage from "@react-native-async-storage/async-storage";
import { useCallback, useEffect, useState } from "react";
import { Task, Goal, TimeBlock, InboxFile, AppSettings, DEFAULT_SETTINGS, STORAGE_KEYS } from "@/lib/types";

/**
 * Generic hook for storing and retrieving data from AsyncStorage
 */
export function useLocalStorage<T>(key: string, defaultValue: T) {
  const [value, setValue] = useState<T>(defaultValue);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  // Load data on mount
  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true);
        const data = await AsyncStorage.getItem(key);
        if (data) {
          setValue(JSON.parse(data));
        }
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to load data"));
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [key]);

  // Save data
  const save = useCallback(
    async (newValue: T | ((prev: T) => T)) => {
      try {
        const valueToSave = typeof newValue === "function" ? (newValue as (prev: T) => T)(value) : newValue;
        setValue(valueToSave);
        await AsyncStorage.setItem(key, JSON.stringify(valueToSave));
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to save data"));
      }
    },
    [key, value],
  );

  // Clear data
  const clear = useCallback(async () => {
    try {
      setValue(defaultValue);
      await AsyncStorage.removeItem(key);
    } catch (err) {
      setError(err instanceof Error ? err : new Error("Failed to clear data"));
    }
  }, [key, defaultValue]);

  return { value, save, clear, loading, error };
}

/**
 * Hook for managing tasks
 */
export function useTasks() {
  const { value: tasks, save, loading, error } = useLocalStorage<Task[]>(STORAGE_KEYS.TASKS, []);

  const addTask = useCallback(
    async (task: Omit<Task, "id" | "createdAt" | "updatedAt">) => {
      const newTask: Task = {
        ...task,
        id: `task_${Date.now()}`,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      await save([...tasks, newTask]);
      return newTask;
    },
    [tasks, save],
  );

  const updateTask = useCallback(
    async (id: string, updates: Partial<Task>) => {
      const updated = tasks.map((t) =>
        t.id === id ? { ...t, ...updates, updatedAt: new Date() } : t,
      );
      await save(updated);
    },
    [tasks, save],
  );

  const deleteTask = useCallback(
    async (id: string) => {
      await save(tasks.filter((t) => t.id !== id));
    },
    [tasks, save],
  );

  const getTask = useCallback(
    (id: string) => tasks.find((t) => t.id === id),
    [tasks],
  );

  const getTodaysTasks = useCallback(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return tasks.filter((t) => t.dueDate >= today && t.dueDate < tomorrow);
  }, [tasks]);

  const getOverdueTasks = useCallback(() => {
    const now = new Date();
    return tasks.filter((t) => !t.completed && t.dueDate < now);
  }, [tasks]);

  return {
    tasks,
    addTask,
    updateTask,
    deleteTask,
    getTask,
    getTodaysTasks,
    getOverdueTasks,
    loading,
    error,
  };
}

/**
 * Hook for managing goals
 */
export function useGoals() {
  const { value: goals, save, loading, error } = useLocalStorage<Goal[]>(STORAGE_KEYS.GOALS, []);

  const addGoal = useCallback(
    async (goal: Omit<Goal, "id" | "createdAt" | "updatedAt">) => {
      const newGoal: Goal = {
        ...goal,
        id: `goal_${Date.now()}`,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      await save([...goals, newGoal]);
      return newGoal;
    },
    [goals, save],
  );

  const updateGoal = useCallback(
    async (id: string, updates: Partial<Goal>) => {
      const updated = goals.map((g) =>
        g.id === id ? { ...g, ...updates, updatedAt: new Date() } : g,
      );
      await save(updated);
    },
    [goals, save],
  );

  const deleteGoal = useCallback(
    async (id: string) => {
      await save(goals.filter((g) => g.id !== id));
    },
    [goals, save],
  );

  const getGoal = useCallback(
    (id: string) => goals.find((g) => g.id === id),
    [goals],
  );

  const getActiveGoals = useCallback(() => goals.filter((g) => !g.archived), [goals]);

  return {
    goals,
    addGoal,
    updateGoal,
    deleteGoal,
    getGoal,
    getActiveGoals,
    loading,
    error,
  };
}

/**
 * Hook for managing time blocks
 */
export function useTimeBlocks() {
  const { value: timeBlocks, save, loading, error } = useLocalStorage<TimeBlock[]>(
    STORAGE_KEYS.TIME_BLOCKS,
    [],
  );

  const addTimeBlock = useCallback(
    async (block: Omit<TimeBlock, "id" | "createdAt" | "updatedAt">) => {
      const newBlock: TimeBlock = {
        ...block,
        id: `block_${Date.now()}`,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      await save([...timeBlocks, newBlock]);
      return newBlock;
    },
    [timeBlocks, save],
  );

  const updateTimeBlock = useCallback(
    async (id: string, updates: Partial<TimeBlock>) => {
      const updated = timeBlocks.map((b) =>
        b.id === id ? { ...b, ...updates, updatedAt: new Date() } : b,
      );
      await save(updated);
    },
    [timeBlocks, save],
  );

  const deleteTimeBlock = useCallback(
    async (id: string) => {
      await save(timeBlocks.filter((b) => b.id !== id));
    },
    [timeBlocks, save],
  );

  const getTimeBlocksForDate = useCallback(
    (date: Date) => {
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);

      return timeBlocks.filter((b) => b.startTime >= startOfDay && b.startTime <= endOfDay);
    },
    [timeBlocks],
  );

  return {
    timeBlocks,
    addTimeBlock,
    updateTimeBlock,
    deleteTimeBlock,
    getTimeBlocksForDate,
    loading,
    error,
  };
}

/**
 * Hook for managing inbox files
 */
export function useInboxFiles() {
  const { value: files, save, loading, error } = useLocalStorage<InboxFile[]>(
    STORAGE_KEYS.INBOX_FILES,
    [],
  );

  const addFile = useCallback(
    async (file: Omit<InboxFile, "id" | "receivedAt">) => {
      const newFile: InboxFile = {
        ...file,
        id: `file_${Date.now()}`,
        receivedAt: new Date(),
      };
      await save([...files, newFile]);
      return newFile;
    },
    [files, save],
  );

  const updateFile = useCallback(
    async (id: string, updates: Partial<InboxFile>) => {
      const updated = files.map((f) => (f.id === id ? { ...f, ...updates } : f));
      await save(updated);
    },
    [files, save],
  );

  const deleteFile = useCallback(
    async (id: string) => {
      await save(files.filter((f) => f.id !== id));
    },
    [files, save],
  );

  const getPendingFiles = useCallback(() => files.filter((f) => f.processingStatus === "pending"), [files]);

  return {
    files,
    addFile,
    updateFile,
    deleteFile,
    getPendingFiles,
    loading,
    error,
  };
}

/**
 * Hook for managing app settings
 */
export function useSettings() {
  const { value: settings, save, loading, error } = useLocalStorage<AppSettings>(
    STORAGE_KEYS.SETTINGS,
    DEFAULT_SETTINGS,
  );

  const updateSettings = useCallback(
    async (updates: Partial<AppSettings>) => {
      await save({ ...settings, ...updates });
    },
    [settings, save],
  );

  return {
    settings,
    updateSettings,
    loading,
    error,
  };
}
