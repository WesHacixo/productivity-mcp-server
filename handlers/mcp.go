package handlers

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/productivity/mcp-server/models"
)

// MCPHandler holds handlers for MCP protocol
type MCPHandler struct {
	taskHandler   *TaskHandler
	goalHandler   *GoalHandler
	claudeHandler *ClaudeHandler
}

// NewMCPHandler creates a new MCP handler
func NewMCPHandler(taskHandler *TaskHandler, goalHandler *GoalHandler, claudeHandler *ClaudeHandler) *MCPHandler {
	return &MCPHandler{
		taskHandler:   taskHandler,
		goalHandler:   goalHandler,
		claudeHandler: claudeHandler,
	}
}

// MCPInitialize handles MCP protocol initialization
func MCPInitialize(c *gin.Context) {
	response := gin.H{
		"jsonrpc": "2.0",
		"id":      1,
		"result": gin.H{
			"protocolVersion": "2024-11-05",
			"capabilities": gin.H{
				"logging": gin.H{},
				"tools":   gin.H{},
			},
			"serverInfo": gin.H{
				"name":    "Productivity MCP Server",
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
			"name":        "create_task",
			"description": "Create a new task in the productivity app",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"title": gin.H{
						"type":        "string",
						"description": "Task title",
					},
					"description": gin.H{
						"type":        "string",
						"description": "Task description",
					},
					"due_date": gin.H{
						"type":        "string",
						"description": "Due date in ISO 8601 format",
					},
					"priority": gin.H{
						"type":        "integer",
						"description": "Priority level (1-5)",
					},
				},
				"required": []string{"title", "due_date"},
			},
		},
		{
			"name":        "create_goal",
			"description": "Create a new goal in the productivity app",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"title": gin.H{
						"type":        "string",
						"description": "Goal title",
					},
					"description": gin.H{
						"type":        "string",
						"description": "Goal description",
					},
					"target_date": gin.H{
						"type":        "string",
						"description": "Target date in ISO 8601 format",
					},
				},
				"required": []string{"title", "target_date"},
			},
		},
		{
			"name":        "parse_task",
			"description": "Parse natural language input into a structured task",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"input": gin.H{
						"type":        "string",
						"description": "Natural language task description",
					},
				},
				"required": []string{"input"},
			},
		},
		{
			"name":        "generate_subtasks",
			"description": "Generate subtasks for a given task",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"task_title": gin.H{
						"type":        "string",
						"description": "Main task title",
					},
					"task_description": gin.H{
						"type":        "string",
						"description": "Task description for context",
					},
				},
				"required": []string{"task_title"},
			},
		},
		{
			"name":        "analyze_productivity",
			"description": "Analyze user productivity patterns and provide insights",
			"inputSchema": gin.H{
				"type": "object",
				"properties": gin.H{
					"days": gin.H{
						"type":        "integer",
						"description": "Number of days to analyze (default: 7)",
					},
				},
			},
		},
	}

	response := gin.H{
		"jsonrpc": "2.0",
		"id":      1,
		"result": gin.H{
			"tools": tools,
		},
	}

	c.JSON(http.StatusOK, response)
}

// MCPCallTool handles tool calls from Claude
func (m *MCPHandler) MCPCallTool(c *gin.Context) {
	var req models.MCPRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"jsonrpc": "2.0",
			"id":      1,
			"error": gin.H{
				"code":    -32700,
				"message": "Parse error",
			},
		})
		return
	}

	// Extract params
	params := req.Params
	if params == nil {
		params = make(map[string]interface{})
	}

	// Route to appropriate handler based on method
	var result interface{}
	var errMsg string

	switch req.Method {
	case "create_task":
		title, _ := params["title"].(string)
		description, _ := params["description"].(string)
		dueDateStr, _ := params["due_date"].(string)
		priority, _ := params["priority"].(float64)
		userID, _ := params["user_id"].(string)

		if title == "" || dueDateStr == "" {
			errMsg = "title and due_date are required"
			break
		}

		dueDate, err := time.Parse(time.RFC3339, dueDateStr)
		if err != nil {
			dueDate, err = time.Parse("2006-01-02T15:04:05Z07:00", dueDateStr)
			if err != nil {
				errMsg = "invalid due_date format"
				break
			}
		}

		if userID != "" {
			c.Set("user_id", userID)
		} else {
			c.Set("user_id", getUserID(c))
		}

		// Create request body
		reqBody := models.CreateTaskRequest{
			Title:       title,
			Description: description,
			DueDate:     dueDate,
			Priority:    int(priority),
		}
		if reqBody.Priority == 0 {
			reqBody.Priority = 3
		}

		// Bind JSON to context
		c.Request.Body = io.NopCloser(bytes.NewBuffer(mustMarshal(reqBody)))
		statusCode, body := captureHandlerResponse(c, m.taskHandler.CreateTask)

		if statusCode == http.StatusCreated {
			var taskData map[string]interface{}
			if err := json.Unmarshal(body, &taskData); err == nil {
				result = taskData
			} else {
				result = gin.H{"status": "created"}
			}
		} else {
			var errData map[string]interface{}
			json.Unmarshal(body, &errData)
			errMsg, _ = errData["error"].(string)
		}

	case "create_goal":
		title, _ := params["title"].(string)
		description, _ := params["description"].(string)
		targetDateStr, _ := params["target_date"].(string)
		userID, _ := params["user_id"].(string)

		if title == "" || targetDateStr == "" {
			errMsg = "title and target_date are required"
			break
		}

		targetDate, err := time.Parse(time.RFC3339, targetDateStr)
		if err != nil {
			targetDate, err = time.Parse("2006-01-02T15:04:05Z07:00", targetDateStr)
			if err != nil {
				errMsg = "invalid target_date format"
				break
			}
		}

		if userID != "" {
			c.Set("user_id", userID)
		} else {
			c.Set("user_id", getUserID(c))
		}

		reqBody := models.CreateGoalRequest{
			Title:       title,
			Description: description,
			StartDate:   time.Now(),
			TargetDate:  targetDate,
		}

		c.Request.Body = io.NopCloser(bytes.NewBuffer(mustMarshal(reqBody)))
		statusCode, body := captureHandlerResponse(c, m.goalHandler.CreateGoal)

		if statusCode == http.StatusCreated {
			var goalData map[string]interface{}
			if err := json.Unmarshal(body, &goalData); err == nil {
				result = goalData
			} else {
				result = gin.H{"status": "created"}
			}
		} else {
			var errData map[string]interface{}
			json.Unmarshal(body, &errData)
			errMsg, _ = errData["error"].(string)
		}

	case "parse_task":
		input, _ := params["input"].(string)
		userID, _ := params["user_id"].(string)

		if input == "" {
			errMsg = "input is required"
			break
		}

		reqBody := models.ParseTaskRequest{
			Input:  input,
			UserID: userID,
		}

		c.Request.Body = io.NopCloser(bytes.NewBuffer(mustMarshal(reqBody)))
		statusCode, body := captureHandlerResponse(c, m.claudeHandler.ParseTask)

		if statusCode == http.StatusOK {
			var parseData map[string]interface{}
			json.Unmarshal(body, &parseData)
			result = parseData
		} else {
			var errData map[string]interface{}
			json.Unmarshal(body, &errData)
			errMsg, _ = errData["error"].(string)
		}

	case "generate_subtasks":
		taskTitle, _ := params["task_title"].(string)
		taskDesc, _ := params["task_description"].(string)
		userID, _ := params["user_id"].(string)

		if taskTitle == "" {
			errMsg = "task_title is required"
			break
		}

		reqBody := models.GenerateSubtasksRequest{
			TaskTitle:       taskTitle,
			TaskDescription: taskDesc,
			UserID:          userID,
		}

		c.Request.Body = io.NopCloser(bytes.NewBuffer(mustMarshal(reqBody)))
		statusCode, body := captureHandlerResponse(c, m.claudeHandler.GenerateSubtasks)

		if statusCode == http.StatusOK {
			var subtaskData map[string]interface{}
			json.Unmarshal(body, &subtaskData)
			result = subtaskData
		} else {
			var errData map[string]interface{}
			json.Unmarshal(body, &errData)
			errMsg, _ = errData["error"].(string)
		}

	case "analyze_productivity":
		userID, _ := params["user_id"].(string)
		days, _ := params["days"].(float64)

		if userID == "" {
			errMsg = "user_id is required"
			break
		}

		reqBody := models.AnalyzeProductivityRequest{
			UserID: userID,
			Days:   int(days),
		}

		c.Request.Body = io.NopCloser(bytes.NewBuffer(mustMarshal(reqBody)))
		statusCode, body := captureHandlerResponse(c, m.claudeHandler.AnalyzeProductivity)

		if statusCode == http.StatusOK {
			var analyzeData map[string]interface{}
			json.Unmarshal(body, &analyzeData)
			result = analyzeData
		} else {
			var errData map[string]interface{}
			json.Unmarshal(body, &errData)
			errMsg, _ = errData["error"].(string)
		}

	default:
		errMsg = "Unknown method: " + req.Method
	}

	if errMsg != "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"jsonrpc": "2.0",
			"id":      req.ID,
			"error": gin.H{
				"code":    -32601,
				"message": errMsg,
			},
		})
		return
	}

	response := gin.H{
		"jsonrpc": "2.0",
		"id":      req.ID,
		"result":  result,
	}

	c.JSON(http.StatusOK, response)
}

func mustMarshal(v interface{}) []byte {
	data, _ := json.Marshal(v)
	return data
}

func captureHandlerResponse(src *gin.Context, handler func(*gin.Context)) (int, []byte) {
	rec := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(rec)
	ctx.Request = src.Request
	if src.Keys != nil {
		for k, v := range src.Keys {
			ctx.Set(k, v)
		}
	}

	handler(ctx)
	return rec.Code, rec.Body.Bytes()
}
