/**
 * Hook for managing tasks via tRPC API (connected to Go MCP server)
 * This replaces the local storage-based useTasks hook
 */

import { useCallback } from "react";
import { trpc } from "@/lib/trpc";
import { Task } from "@/lib/types";

// Hook for managing tasks via tRPC API
// Uses protectedProcedure - user ID comes from authenticated context automatically
// SECURE: Uses MySQL user.id (internal integer), not external OAuth identifiers
export function useTasksAPI() {
  const utils = trpc.useUtils();
  
  // Queries - protectedProcedure automatically uses authenticated user's ID
  const { data: tasks = [], isLoading, error } = trpc.task.list.useQuery(
    undefined, // No input needed - user ID from auth context
    { refetchOnWindowFocus: true }
  );

  // Mutations
  const createMutation = trpc.task.create.useMutation({
    onSuccess: () => {
      utils.task.list.invalidate(); // Invalidate without userId param
    },
  });

  const updateMutation = trpc.task.update.useMutation({
    onSuccess: () => {
      utils.task.list.invalidate();
    },
  });

  const deleteMutation = trpc.task.delete.useMutation({
    onSuccess: () => {
      utils.task.list.invalidate();
    },
  });

  // Helper functions
  const addTask = useCallback(
    async (task: Omit<Task, "id" | "createdAt" | "updatedAt" | "subtasks" | "attachments" | "relatedGoals">) => {
      const result = await createMutation.mutateAsync({
        title: task.title,
        description: task.description,
        priority: task.priority,
        dueDate: task.dueDate.toISOString(),
        estimatedDuration: task.estimatedDuration,
        category: task.category,
        // userId comes from authenticated context automatically
      });
      return result;
    },
    [createMutation]
  );

  const updateTask = useCallback(
    async (id: string, updates: Partial<Task>) => {
      const updateData: any = {};
      if (updates.title !== undefined) updateData.title = updates.title;
      if (updates.description !== undefined) updateData.description = updates.description;
      if (updates.priority !== undefined) updateData.priority = updates.priority;
      if (updates.dueDate !== undefined) updateData.dueDate = updates.dueDate.toISOString();
      if (updates.estimatedDuration !== undefined) updateData.estimatedDuration = updates.estimatedDuration;
      if (updates.category !== undefined) updateData.category = updates.category;
      if (updates.completed !== undefined) updateData.completed = updates.completed;

      await updateMutation.mutateAsync({ id, ...updateData });
    },
    [updateMutation]
  );

  const deleteTask = useCallback(
    async (id: string) => {
      await deleteMutation.mutateAsync({ id });
    },
    [deleteMutation]
  );

  const getTask = useCallback(
    (id: string) => tasks.find((t) => t.id === id),
    [tasks]
  );

  const getTodaysTasks = useCallback(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return tasks.filter((t) => {
      const dueDate = t.dueDate instanceof Date ? t.dueDate : new Date(t.dueDate);
      return dueDate >= today && dueDate < tomorrow;
    });
  }, [tasks]);

  const getOverdueTasks = useCallback(() => {
    const now = new Date();
    return tasks.filter((t) => {
      const dueDate = t.dueDate instanceof Date ? t.dueDate : new Date(t.dueDate);
      return !t.completed && dueDate < now;
    });
  }, [tasks]);

  return {
    tasks: tasks.map((t) => ({
      ...t,
      dueDate: t.dueDate instanceof Date ? t.dueDate : new Date(t.dueDate),
      createdAt: t.createdAt instanceof Date ? t.createdAt : new Date(t.createdAt),
      updatedAt: t.updatedAt instanceof Date ? t.updatedAt : new Date(t.updatedAt),
      completedAt: t.completedAt ? (t.completedAt instanceof Date ? t.completedAt : new Date(t.completedAt)) : undefined,
    })) as Task[],
    addTask,
    updateTask,
    deleteTask,
    getTask,
    getTodaysTasks,
    getOverdueTasks,
    loading: isLoading,
    error,
  };
}
