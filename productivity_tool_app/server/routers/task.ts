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

export const taskRouter = router({
  // All routes require authentication (protectedProcedure)
  // Uses MySQL user.id (internal integer) - secure, not PII
  list: protectedProcedure
    .query(async ({ ctx }) => {
      const userId = getUserId(ctx);
      const tasks = await callMCPServer(`/api/tasks/user/${userId}`, "GET", undefined, userId);
      // Transform from Supabase format to app format
      return Array.isArray(tasks) ? tasks.map(transformTask) : [];
    }),

  get: protectedProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input }) => {
      const task = await callMCPServer(`/api/tasks/${input.id}`);
      return transformTask(task);
    }),

  create: protectedProcedure
    .input(
      z.object({
        title: z.string(),
        description: z.string().optional(),
        priority: z.number().min(1).max(5).optional(),
        dueDate: z.string(), // ISO 8601 string
        estimatedDuration: z.number().optional(),
        category: z.string().optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const userId = getUserId(ctx);
      // Go server expects user_id as query param: ?user_id=xxx
      const task = await callMCPServer(
        `/api/tasks?user_id=${userId}`,
        "POST",
        {
          title: input.title,
          description: input.description || "",
          priority: input.priority || 3,
          due_date: input.dueDate,
          estimated_duration: input.estimatedDuration || 0,
          category: input.category || "work",
        },
        userId
      );
      return transformTask(task);
    }),

  update: protectedProcedure
    .input(
      z.object({
        id: z.string(),
        title: z.string().optional(),
        description: z.string().optional(),
        priority: z.number().min(1).max(5).optional(),
        dueDate: z.string().optional(),
        estimatedDuration: z.number().optional(),
        category: z.string().optional(),
        completed: z.boolean().optional(),
      })
    )
    .mutation(async ({ input }) => {
      const updateData: any = {};
      if (input.title !== undefined) updateData.title = input.title;
      if (input.description !== undefined) updateData.description = input.description;
      if (input.priority !== undefined) updateData.priority = input.priority;
      if (input.dueDate !== undefined) updateData.due_date = input.dueDate;
      if (input.estimatedDuration !== undefined) updateData.estimated_duration = input.estimatedDuration;
      if (input.category !== undefined) updateData.category = input.category;
      if (input.completed !== undefined) updateData.completed = input.completed;

      const task = await callMCPServer(`/api/tasks/${input.id}`, "PUT", updateData);
      return transformTask(task);
    }),

  delete: protectedProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ input }) => {
      await callMCPServer(`/api/tasks/${input.id}`, "DELETE");
      return { success: true };
    }),
});

// Transform Supabase task format to app Task format
function transformTask(task: any): any {
  return {
    id: task.id,
    title: task.title || "",
    description: task.description || "",
    priority: task.priority || 3,
    dueDate: task.due_date ? new Date(task.due_date) : new Date(),
    estimatedDuration: task.estimated_duration || 0,
    category: task.category || "work",
    completed: task.completed || false,
    completedAt: task.completed_at ? new Date(task.completed_at) : undefined,
    subtasks: [], // TODO: Map from Supabase if available
    attachments: [], // TODO: Map from Supabase if available
    relatedGoals: [], // TODO: Map from Supabase if available
    createdAt: task.created_at ? new Date(task.created_at) : new Date(),
    updatedAt: task.updated_at ? new Date(task.updated_at) : new Date(),
  };
}
