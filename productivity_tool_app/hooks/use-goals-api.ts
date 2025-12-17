/**
 * Hook for managing goals via tRPC API (connected to Go MCP server)
 * This replaces the local storage-based useGoals hook
 */

import { useCallback } from "react";
import { trpc } from "@/lib/trpc";
import { Goal } from "@/lib/types";

// Hook for managing goals via tRPC API
// Uses protectedProcedure - user ID comes from authenticated context automatically
// SECURE: Uses MySQL user.id (internal integer), not external OAuth identifiers
export function useGoalsAPI() {
  const utils = trpc.useUtils();
  
  // Queries - protectedProcedure automatically uses authenticated user's ID
  const { data: goals = [], isLoading, error } = trpc.goal.list.useQuery(
    undefined, // No input needed - user ID from auth context
    { refetchOnWindowFocus: true }
  );

  // Mutations
  const createMutation = trpc.goal.create.useMutation({
    onSuccess: () => {
      utils.goal.list.invalidate(); // Invalidate without userId param
    },
  });

  const updateMutation = trpc.goal.update.useMutation({
    onSuccess: () => {
      utils.goal.list.invalidate();
    },
  });

  const deleteMutation = trpc.goal.delete.useMutation({
    onSuccess: () => {
      utils.goal.list.invalidate();
    },
  });

  // Helper functions
  const addGoal = useCallback(
    async (goal: Omit<Goal, "id" | "createdAt" | "updatedAt" | "milestones" | "relatedTasks">) => {
      const result = await createMutation.mutateAsync({
        title: goal.title,
        description: goal.description,
        startDate: goal.startDate.toISOString(),
        targetDate: goal.targetDate.toISOString(),
        progress: goal.progress,
        // userId comes from authenticated context automatically
      });
      return result;
    },
    [createMutation]
  );

  const updateGoal = useCallback(
    async (id: string, updates: Partial<Goal>) => {
      const updateData: any = {};
      if (updates.title !== undefined) updateData.title = updates.title;
      if (updates.description !== undefined) updateData.description = updates.description;
      if (updates.startDate !== undefined) updateData.startDate = updates.startDate.toISOString();
      if (updates.targetDate !== undefined) updateData.targetDate = updates.targetDate.toISOString();
      if (updates.progress !== undefined) updateData.progress = updates.progress;
      if (updates.archived !== undefined) updateData.archived = updates.archived;

      await updateMutation.mutateAsync({ id, ...updateData });
    },
    [updateMutation]
  );

  const deleteGoal = useCallback(
    async (id: string) => {
      await deleteMutation.mutateAsync({ id });
    },
    [deleteMutation]
  );

  const getGoal = useCallback(
    (id: string) => goals.find((g) => g.id === id),
    [goals]
  );

  const getActiveGoals = useCallback(
    () => goals.filter((g) => !g.archived),
    [goals]
  );

  return {
    goals: goals.map((g) => ({
      ...g,
      startDate: g.startDate instanceof Date ? g.startDate : new Date(g.startDate),
      targetDate: g.targetDate instanceof Date ? g.targetDate : new Date(g.targetDate),
      createdAt: g.createdAt instanceof Date ? g.createdAt : new Date(g.createdAt),
      updatedAt: g.updatedAt instanceof Date ? g.updatedAt : new Date(g.updatedAt),
    })) as Goal[],
    addGoal,
    updateGoal,
    deleteGoal,
    getGoal,
    getActiveGoals,
    loading: isLoading,
    error,
  };
}
