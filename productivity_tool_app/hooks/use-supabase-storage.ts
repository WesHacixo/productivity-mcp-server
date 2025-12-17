/**
 * Supabase-based storage hooks
 * Provides cloud-synced data operations with real-time updates
 */

import { useCallback, useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Task, Goal, TimeBlock, InboxFile } from "@/lib/types";

/**
 * Hook for managing cloud-synced tasks
 */
export function useSupabaseTasks() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  // Load tasks from Supabase
  useEffect(() => {
    const loadTasks = async () => {
      try {
        setLoading(true);
        const { data, error: fetchError } = await supabase
          .from("tasks")
          .select("*")
          .order("due_date", { ascending: true });

        if (fetchError) throw fetchError;

        // Convert database rows to Task objects
        const formattedTasks = (data || []).map((row: any) => ({
          ...row,
          due_date: new Date(row.due_date),
          completed_at: row.completed_at ? new Date(row.completed_at) : undefined,
          created_at: new Date(row.created_at),
          updated_at: new Date(row.updated_at),
          subtasks: [],
          attachments: [],
          related_goals: [],
        }));

        setTasks(formattedTasks);
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to load tasks"));
      } finally {
        setLoading(false);
      }
    };

    loadTasks();

    // Subscribe to real-time updates
    const subscription = supabase
      .channel("tasks")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "tasks" },
        (payload: any) => {
          if (payload.eventType === "INSERT") {
            setTasks((prev) => [...prev, payload.new]);
          } else if (payload.eventType === "UPDATE") {
            setTasks((prev) =>
              prev.map((t) => (t.id === payload.new.id ? payload.new : t))
            );
          } else if (payload.eventType === "DELETE") {
            setTasks((prev) => prev.filter((t) => t.id !== payload.old.id));
          }
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const addTask = useCallback(
    async (task: Omit<Task, "id" | "createdAt" | "updatedAt">) => {
      try {
        const { data, error: insertError } = await supabase
          .from("tasks")
          .insert([
            {
              title: task.title,
              description: task.description,
              priority: task.priority,
              due_date: task.dueDate.toISOString(),
              estimated_duration: task.estimatedDuration,
              category: task.category,
              completed: task.completed,
            },
          ])
          .select()
          .single();

        if (insertError) throw insertError;
        return data;
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to add task"));
        throw err;
      }
    },
    []
  );

  const updateTask = useCallback(
    async (id: string, updates: Partial<Task>) => {
      try {
        const { error: updateError } = await supabase
          .from("tasks")
          .update({
            ...updates,
            updated_at: new Date().toISOString(),
          })
          .eq("id", id);

        if (updateError) throw updateError;
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to update task"));
        throw err;
      }
    },
    []
  );

  const deleteTask = useCallback(async (id: string) => {
    try {
      const { error: deleteError } = await supabase
        .from("tasks")
        .delete()
        .eq("id", id);

      if (deleteError) throw deleteError;
    } catch (err) {
      setError(err instanceof Error ? err : new Error("Failed to delete task"));
      throw err;
    }
  }, []);

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
    getTodaysTasks,
    getOverdueTasks,
    loading,
    error,
  };
}

/**
 * Hook for managing cloud-synced goals
 */
export function useSupabaseGoals() {
  const [goals, setGoals] = useState<Goal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const loadGoals = async () => {
      try {
        setLoading(true);
        const { data, error: fetchError } = await supabase
          .from("goals")
          .select("*")
          .order("target_date", { ascending: true });

        if (fetchError) throw fetchError;

        const formattedGoals = (data || []).map((row: any) => ({
          ...row,
          start_date: new Date(row.start_date),
          target_date: new Date(row.target_date),
          created_at: new Date(row.created_at),
          updated_at: new Date(row.updated_at),
          milestones: [],
          related_tasks: [],
        }));

        setGoals(formattedGoals);
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to load goals"));
      } finally {
        setLoading(false);
      }
    };

    loadGoals();

    const subscription = supabase
      .channel("goals")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "goals" },
        (payload: any) => {
          if (payload.eventType === "INSERT") {
            setGoals((prev) => [...prev, payload.new]);
          } else if (payload.eventType === "UPDATE") {
            setGoals((prev) =>
              prev.map((g) => (g.id === payload.new.id ? payload.new : g))
            );
          } else if (payload.eventType === "DELETE") {
            setGoals((prev) => prev.filter((g) => g.id !== payload.old.id));
          }
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const addGoal = useCallback(
    async (goal: Omit<Goal, "id" | "createdAt" | "updatedAt">) => {
      try {
        const { data, error: insertError } = await supabase
          .from("goals")
          .insert([
            {
              title: goal.title,
              description: goal.description,
              start_date: goal.startDate.toISOString(),
              target_date: goal.targetDate.toISOString(),
              progress: goal.progress,
              archived: goal.archived,
            },
          ])
          .select()
          .single();

        if (insertError) throw insertError;
        return data;
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to add goal"));
        throw err;
      }
    },
    []
  );

  const updateGoal = useCallback(
    async (id: string, updates: Partial<Goal>) => {
      try {
        const { error: updateError } = await supabase
          .from("goals")
          .update({
            ...updates,
            updated_at: new Date().toISOString(),
          })
          .eq("id", id);

        if (updateError) throw updateError;
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to update goal"));
        throw err;
      }
    },
    []
  );

  const deleteGoal = useCallback(async (id: string) => {
    try {
      const { error: deleteError } = await supabase
        .from("goals")
        .delete()
        .eq("id", id);

      if (deleteError) throw deleteError;
    } catch (err) {
      setError(err instanceof Error ? err : new Error("Failed to delete goal"));
      throw err;
    }
  }, []);

  const getActiveGoals = useCallback(
    () => goals.filter((g) => !g.archived),
    [goals]
  );

  return {
    goals,
    addGoal,
    updateGoal,
    deleteGoal,
    getActiveGoals,
    loading,
    error,
  };
}

/**
 * Hook for managing cloud-synced time blocks
 */
export function useSupabaseTimeBlocks() {
  const [timeBlocks, setTimeBlocks] = useState<TimeBlock[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const loadTimeBlocks = async () => {
      try {
        setLoading(true);
        const { data, error: fetchError } = await supabase
          .from("time_blocks")
          .select("*")
          .order("start_time", { ascending: true });

        if (fetchError) throw fetchError;

        const formattedBlocks = (data || []).map((row: any) => ({
          ...row,
          start_time: new Date(row.start_time),
          end_time: new Date(row.end_time),
          completed_at: row.completed_at ? new Date(row.completed_at) : undefined,
          created_at: new Date(row.created_at),
          updated_at: new Date(row.updated_at),
        }));

        setTimeBlocks(formattedBlocks);
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to load time blocks"));
      } finally {
        setLoading(false);
      }
    };

    loadTimeBlocks();

    const subscription = supabase
      .channel("time_blocks")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "time_blocks" },
        (payload: any) => {
          if (payload.eventType === "INSERT") {
            setTimeBlocks((prev) => [...prev, payload.new]);
          } else if (payload.eventType === "UPDATE") {
            setTimeBlocks((prev) =>
              prev.map((b) => (b.id === payload.new.id ? payload.new : b))
            );
          } else if (payload.eventType === "DELETE") {
            setTimeBlocks((prev) => prev.filter((b) => b.id !== payload.old.id));
          }
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const addTimeBlock = useCallback(
    async (block: Omit<TimeBlock, "id" | "createdAt" | "updatedAt">) => {
      try {
        const { data, error: insertError } = await supabase
          .from("time_blocks")
          .insert([
            {
              task_id: block.taskId,
              start_time: block.startTime.toISOString(),
              end_time: block.endTime.toISOString(),
              category: block.category,
              actual_duration: block.actualDuration,
              completed: block.completed,
            },
          ])
          .select()
          .single();

        if (insertError) throw insertError;
        return data;
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to add time block"));
        throw err;
      }
    },
    []
  );

  const updateTimeBlock = useCallback(
    async (id: string, updates: Partial<TimeBlock>) => {
      try {
        const { error: updateError } = await supabase
          .from("time_blocks")
          .update({
            ...updates,
            updated_at: new Date().toISOString(),
          })
          .eq("id", id);

        if (updateError) throw updateError;
      } catch (err) {
        setError(err instanceof Error ? err : new Error("Failed to update time block"));
        throw err;
      }
    },
    []
  );

  const deleteTimeBlock = useCallback(async (id: string) => {
    try {
      const { error: deleteError } = await supabase
        .from("time_blocks")
        .delete()
        .eq("id", id);

      if (deleteError) throw deleteError;
    } catch (err) {
      setError(err instanceof Error ? err : new Error("Failed to delete time block"));
      throw err;
    }
  }, []);

  const getTimeBlocksForDate = useCallback((date: Date) => {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    return timeBlocks.filter(
      (b) => b.startTime >= startOfDay && b.startTime <= endOfDay
    );
  }, [timeBlocks]);

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
