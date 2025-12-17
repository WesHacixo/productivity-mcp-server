import { z } from "zod";
import { protectedProcedure, router } from "../_core/trpc";
import axios from "axios";

import { ENV } from "../_core/env";

const MCP_SERVER_URL = ENV.mcpServerUrl;

// Helper to get user ID from context
// Uses MySQL user.id (internal integer) - secure, not PII
// protectedProcedure guarantees ctx.user exists
function getUserId(ctx: { user: { id: number } }): string {
  // Use MySQL internal user.id (integer), not openId
  // This is secure: internal ID, not external identifier or PII
  return ctx.user.id.toString();
}

// Helper to call MCP server
async function callMCPServer(endpoint: string, method: string = "GET", data?: any, userId?: string) {
  const url = `${MCP_SERVER_URL}${endpoint}`;
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  
  if (userId) {
    headers["X-User-ID"] = userId;
  }

  try {
    const response = await axios({
      method,
      url,
      data,
      headers,
      timeout: 10000,
    });
    return response.data;
  } catch (error: any) {
    if (error.response) {
      throw new Error(error.response.data?.error || error.response.statusText || "MCP server error");
    }
    throw new Error(`Failed to connect to MCP server: ${error.message}`);
  }
}

export const goalRouter = router({
  // All routes require authentication (protectedProcedure)
  // Uses MySQL user.id (internal integer) - secure, not PII
  list: protectedProcedure
    .query(async ({ ctx }) => {
      const userId = getUserId(ctx);
      const goals = await callMCPServer(`/api/goals/user/${userId}`, "GET", undefined, userId);
      return Array.isArray(goals) ? goals.map(transformGoal) : [];
    }),

  get: protectedProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input }) => {
      const goal = await callMCPServer(`/api/goals/${input.id}`);
      return transformGoal(goal);
    }),

  create: protectedProcedure
    .input(
      z.object({
        title: z.string(),
        description: z.string().optional(),
        startDate: z.string(), // ISO 8601 string
        targetDate: z.string(), // ISO 8601 string
        progress: z.number().min(0).max(100).optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const userId = getUserId(ctx);
      const goal = await callMCPServer(
        `/api/goals`,
        "POST",
        {
          title: input.title,
          description: input.description || "",
          start_date: input.startDate,
          target_date: input.targetDate,
          progress: input.progress || 0,
        },
        userId
      );
      return transformGoal(goal);
    }),

  update: protectedProcedure
    .input(
      z.object({
        id: z.string(),
        title: z.string().optional(),
        description: z.string().optional(),
        startDate: z.string().optional(),
        targetDate: z.string().optional(),
        progress: z.number().min(0).max(100).optional(),
        archived: z.boolean().optional(),
      })
    )
    .mutation(async ({ input }) => {
      const updateData: any = {};
      if (input.title !== undefined) updateData.title = input.title;
      if (input.description !== undefined) updateData.description = input.description;
      if (input.startDate !== undefined) updateData.start_date = input.startDate;
      if (input.targetDate !== undefined) updateData.target_date = input.targetDate;
      if (input.progress !== undefined) updateData.progress = input.progress;
      if (input.archived !== undefined) updateData.archived = input.archived;

      const goal = await callMCPServer(`/api/goals/${input.id}`, "PUT", updateData);
      return transformGoal(goal);
    }),

  delete: protectedProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ input }) => {
      await callMCPServer(`/api/goals/${input.id}`, "DELETE");
      return { success: true };
    }),
});

// Transform Supabase goal format to app Goal format
function transformGoal(goal: any): any {
  return {
    id: goal.id,
    title: goal.title || "",
    description: goal.description || "",
    startDate: goal.start_date ? new Date(goal.start_date) : new Date(),
    targetDate: goal.target_date ? new Date(goal.target_date) : new Date(),
    progress: goal.progress || 0,
    milestones: [], // TODO: Map from Supabase if available
    relatedTasks: [], // TODO: Map from Supabase if available
    archived: goal.archived || false,
    createdAt: goal.created_at ? new Date(goal.created_at) : new Date(),
    updatedAt: goal.updated_at ? new Date(goal.updated_at) : new Date(),
  };
}
