#!/usr/bin/env node

/**
 * Productivity MCP Server - Claude Desktop Extension
 * 
 * This MCP server provides tools for managing tasks and goals
 * by connecting to the Railway-hosted productivity API.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ErrorCode,
  McpError,
} from "@modelcontextprotocol/sdk/types.js";

// Configuration from user_config in manifest.json
const API_URL = process.env.MCP_USER_CONFIG_API_URL || 
  "https://productivity-mcp-server-production.up.railway.app";
const API_KEY = process.env.MCP_USER_CONFIG_API_KEY || "";

// Create MCP server
const server = new Server(
  {
    name: "productivity-mcp-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Helper function to make API requests
async function apiRequest(endpoint, options = {}) {
  const url = `${API_URL}${endpoint}`;
  const headers = {
    "Content-Type": "application/json",
    ...options.headers,
  };

  if (API_KEY) {
    headers["Authorization"] = `Bearer ${API_KEY}`;
  }

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`API request failed: ${response.status} ${errorText}`);
    }

    return await response.json();
  } catch (error) {
    throw new Error(`API request error: ${error.message}`);
  }
}

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "list_tasks",
        description: "List all tasks for a user. Can filter by completed status, category, or priority.",
        inputSchema: {
          type: "object",
          properties: {
            userId: {
              type: "string",
              description: "User ID to fetch tasks for",
            },
            completed: {
              type: "boolean",
              description: "Filter by completed status (optional)",
            },
            category: {
              type: "string",
              description: "Filter by category (optional)",
            },
            priority: {
              type: "number",
              description: "Filter by priority (1-5, optional)",
            },
          },
          required: ["userId"],
        },
      },
      {
        name: "create_task",
        description: "Create a new task with title, description, due date, priority, and category.",
        inputSchema: {
          type: "object",
          properties: {
            userId: {
              type: "string",
              description: "User ID who owns the task",
            },
            title: {
              type: "string",
              description: "Task title",
            },
            description: {
              type: "string",
              description: "Task description (optional)",
            },
            dueDate: {
              type: "string",
              description: "Due date in ISO 8601 format (e.g., 2024-12-20T17:00:00Z)",
            },
            priority: {
              type: "number",
              description: "Priority level (1-5, where 5 is highest)",
            },
            category: {
              type: "string",
              description: "Task category (e.g., 'work', 'personal', 'health')",
            },
            estimatedDuration: {
              type: "number",
              description: "Estimated duration in minutes (optional)",
            },
          },
          required: ["userId", "title", "dueDate"],
        },
      },
      {
        name: "update_task",
        description: "Update an existing task. Only provide fields you want to change.",
        inputSchema: {
          type: "object",
          properties: {
            taskId: {
              type: "string",
              description: "Task ID to update",
            },
            title: {
              type: "string",
              description: "New title (optional)",
            },
            description: {
              type: "string",
              description: "New description (optional)",
            },
            completed: {
              type: "boolean",
              description: "Mark task as completed/incomplete (optional)",
            },
            priority: {
              type: "number",
              description: "New priority (1-5, optional)",
            },
            category: {
              type: "string",
              description: "New category (optional)",
            },
          },
          required: ["taskId"],
        },
      },
      {
        name: "delete_task",
        description: "Delete a task by ID",
        inputSchema: {
          type: "object",
          properties: {
            taskId: {
              type: "string",
              description: "Task ID to delete",
            },
          },
          required: ["taskId"],
        },
      },
      {
        name: "list_goals",
        description: "List all goals for a user. Can filter by archived status.",
        inputSchema: {
          type: "object",
          properties: {
            userId: {
              type: "string",
              description: "User ID to fetch goals for",
            },
            archived: {
              type: "boolean",
              description: "Filter by archived status (optional)",
            },
          },
          required: ["userId"],
        },
      },
      {
        name: "create_goal",
        description: "Create a new goal with title, description, start date, and target date.",
        inputSchema: {
          type: "object",
          properties: {
            userId: {
              type: "string",
              description: "User ID who owns the goal",
            },
            title: {
              type: "string",
              description: "Goal title",
            },
            description: {
              type: "string",
              description: "Goal description (optional)",
            },
            startDate: {
              type: "string",
              description: "Start date in ISO 8601 format",
            },
            targetDate: {
              type: "string",
              description: "Target completion date in ISO 8601 format",
            },
            progress: {
              type: "number",
              description: "Initial progress (0-100, optional, defaults to 0)",
            },
          },
          required: ["userId", "title", "startDate", "targetDate"],
        },
      },
      {
        name: "update_goal",
        description: "Update an existing goal. Only provide fields you want to change.",
        inputSchema: {
          type: "object",
          properties: {
            goalId: {
              type: "string",
              description: "Goal ID to update",
            },
            title: {
              type: "string",
              description: "New title (optional)",
            },
            description: {
              type: "string",
              description: "New description (optional)",
            },
            progress: {
              type: "number",
              description: "New progress (0-100, optional)",
            },
            archived: {
              type: "boolean",
              description: "Archive/unarchive goal (optional)",
            },
          },
          required: ["goalId"],
        },
      },
      {
        name: "delete_goal",
        description: "Delete a goal by ID",
        inputSchema: {
          type: "object",
          properties: {
            goalId: {
              type: "string",
              description: "Goal ID to delete",
          },
          },
          required: ["goalId"],
        },
      },
      {
        name: "parse_task",
        description: "Parse natural language input into a structured task using AI.",
        inputSchema: {
          type: "object",
          properties: {
            input: {
              type: "string",
              description: "Natural language description of the task (e.g., 'Finish report by Friday at 5pm')",
            },
            userId: {
              type: "string",
              description: "User ID for the task",
            },
          },
          required: ["input", "userId"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "list_tasks": {
        const { userId, completed, category, priority } = args;
        let endpoint = `/api/tasks/user/${userId}`;
        const params = new URLSearchParams();
        if (completed !== undefined) params.append("completed", completed);
        if (category) params.append("category", category);
        if (priority !== undefined) params.append("priority", priority);
        if (params.toString()) endpoint += `?${params.toString()}`;

        const tasks = await apiRequest(endpoint);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(tasks, null, 2),
            },
          ],
        };
      }

      case "create_task": {
        const { userId, title, description, dueDate, priority, category, estimatedDuration } = args;
        const task = await apiRequest("/api/tasks", {
          method: "POST",
          body: JSON.stringify({
            user_id: userId,
            title,
            description: description || "",
            due_date: dueDate,
            priority: priority || 3,
            category: category || "general",
            estimated_duration: estimatedDuration || 0,
          }),
        });
        return {
          content: [
            {
              type: "text",
              text: `Task created successfully:\n${JSON.stringify(task, null, 2)}`,
            },
          ],
        };
      }

      case "update_task": {
        const { taskId, ...updates } = args;
        const task = await apiRequest(`/api/tasks/${taskId}`, {
          method: "PUT",
          body: JSON.stringify(updates),
        });
        return {
          content: [
            {
              type: "text",
              text: `Task updated successfully:\n${JSON.stringify(task, null, 2)}`,
            },
          ],
        };
      }

      case "delete_task": {
        const { taskId } = args;
        await apiRequest(`/api/tasks/${taskId}`, {
          method: "DELETE",
        });
        return {
          content: [
            {
              type: "text",
              text: `Task ${taskId} deleted successfully`,
            },
          ],
        };
      }

      case "list_goals": {
        const { userId, archived } = args;
        let endpoint = `/api/goals/user/${userId}`;
        if (archived !== undefined) {
          endpoint += `?archived=${archived}`;
        }
        const goals = await apiRequest(endpoint);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(goals, null, 2),
            },
          ],
        };
      }

      case "create_goal": {
        const { userId, title, description, startDate, targetDate, progress } = args;
        const goal = await apiRequest("/api/goals", {
          method: "POST",
          body: JSON.stringify({
            user_id: userId,
            title,
            description: description || "",
            start_date: startDate,
            target_date: targetDate,
            progress: progress || 0,
          }),
        });
        return {
          content: [
            {
              type: "text",
              text: `Goal created successfully:\n${JSON.stringify(goal, null, 2)}`,
            },
          ],
        };
      }

      case "update_goal": {
        const { goalId, ...updates } = args;
        const goal = await apiRequest(`/api/goals/${goalId}`, {
          method: "PUT",
          body: JSON.stringify(updates),
        });
        return {
          content: [
            {
              type: "text",
              text: `Goal updated successfully:\n${JSON.stringify(goal, null, 2)}`,
            },
          ],
        };
      }

      case "delete_goal": {
        const { goalId } = args;
        await apiRequest(`/api/goals/${goalId}`, {
          method: "DELETE",
        });
        return {
          content: [
            {
              type: "text",
              text: `Goal ${goalId} deleted successfully`,
            },
          ],
        };
      }

      case "parse_task": {
        const { input, userId } = args;
        const result = await apiRequest("/api/mcp/parse-task", {
          method: "POST",
          body: JSON.stringify({
            input,
            user_id: userId,
          }),
        });
        return {
          content: [
            {
              type: "text",
              text: `Parsed task:\n${JSON.stringify(result, null, 2)}`,
            },
          ],
        };
      }

      default:
        throw new McpError(
          ErrorCode.MethodNotFound,
          `Unknown tool: ${name}`
        );
    }
  } catch (error) {
    throw new McpError(
      ErrorCode.InternalError,
      `Error executing tool ${name}: ${error.message}`
    );
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Productivity MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
