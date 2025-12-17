package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/productivity/mcp-server/models"
)

// MCPInitialize handles MCP protocol initialization
func MCPInitialize(c *gin.Context) {
	response := gin.H{
		"jsonrpc": "2.0",
		"id": 1,
		"result": gin.H{
			"protocolVersion": "2024-11-05",
			"capabilities": gin.H{
				"logging": gin.H{},
				"tools": gin.H{},
			},
			"serverInfo": gin.H{
				"name": "Productivity MCP Server",
				"version": "1.0.0",
			},
		},
	}

	c.JSON(http.StatusOK, response)
}

// MCPListTools returns available tools for Claude
func MCPListTools(c *gin.Context) {
	tools := []gin.H{
		{
			"name": "create_task",
			"description": "Create a new task in the productivity app",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"title": gin.H{
						"type": "string",
						"description": "Task title",
					},
					"description": gin.H{
						"type": "string",
						"description": "Task description",
					},
					"due_date": gin.H{
						"type": "string",
						"description": "Due date in ISO 8601 format",
					},
					"priority": gin.H{
						"type": "integer",
						"description": "Priority level (1-5)",
					},
				},
				"required": []string{"title", "due_date"},
			},
		},
		{
			"name": "create_goal",
			"description": "Create a new goal in the productivity app",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"title": gin.H{
						"type": "string",
						"description": "Goal title",
					},
					"description": gin.H{
						"type": "string",
						"description": "Goal description",
					},
					"target_date": gin.H{
						"type": "string",
						"description": "Target date in ISO 8601 format",
					},
				},
				"required": []string{"title", "target_date"},
			},
		},
		{
			"name": "parse_task",
			"description": "Parse natural language input into a structured task",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"input": gin.H{
						"type": "string",
						"description": "Natural language task description",
					},
				},
				"required": []string{"input"},
			},
		},
		{
			"name": "generate_subtasks",
			"description": "Generate subtasks for a given task",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"task_title": gin.H{
						"type": "string",
						"description": "Main task title",
					},
					"task_description": gin.H{
						"type": "string",
						"description": "Task description for context",
					},
				},
				"required": []string{"task_title"},
			},
		},
		{
			"name": "analyze_productivity",
			"description": "Analyze user productivity patterns and provide insights",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"days": gin.H{
						"type": "integer",
						"description": "Number of days to analyze (default: 7)",
					},
				},
			},
		},
	}

	response := gin.H{
		"jsonrpc": "2.0",
		"id": 1,
		"result": gin.H{
			"tools": tools,
		},
	}

	c.JSON(http.StatusOK, response)
}

// MCPCallTool handles tool calls from Claude
func MCPCallTool(c *gin.Context) {
	var req models.MCPRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"jsonrpc": "2.0",
			"id": 1,
			"error": gin.H{
				"code": -32700,
				"message": "Parse error",
			},
		})
		return
	}

	// Route to appropriate handler based on method
	var result interface{}
	var errMsg string

	switch req.Method {
	case "create_task":
		result = gin.H{"id": "task-123", "status": "created"}
	case "create_goal":
		result = gin.H{"id": "goal-123", "status": "created"}
	case "parse_task":
		result = gin.H{
			"title": "Example task",
			"due_date": "2024-12-20",
			"priority": 2,
		}
	case "generate_subtasks":
		result = gin.H{
			"subtasks": []string{"Subtask 1", "Subtask 2", "Subtask 3"},
		}
	case "analyze_productivity":
		result = gin.H{
			"completed_tasks": 10,
			"total_tasks": 15,
			"completion_rate": 0.67,
		}
	default:
		errMsg = "Unknown method"
	}

	if errMsg != "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"jsonrpc": "2.0",
			"id": req.ID,
			"error": gin.H{
				"code": -32601,
				"message": errMsg,
			},
		})
		return
	}

	response := gin.H{
		"jsonrpc": "2.0",
		"id": req.ID,
		"result": result,
	}

	c.JSON(http.StatusOK, response)
}
