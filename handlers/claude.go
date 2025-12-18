package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/productivity/mcp-server/db"
	"github.com/productivity/mcp-server/models"
)

// ClaudeHandler handles Claude AI integration
type ClaudeHandler struct {
	supabaseURL  string
	supabaseKey  string
	claudeAPIKey string
	httpClient   *http.Client
}

// NewClaudeHandler creates a new Claude handler
func NewClaudeHandler(supabaseURL, supabaseKey, claudeAPIKey string) *ClaudeHandler {
	return &ClaudeHandler{
		supabaseURL:  supabaseURL,
		supabaseKey:  supabaseKey,
		claudeAPIKey: claudeAPIKey,
		httpClient:   &http.Client{Timeout: 30 * time.Second},
	}
}

// callClaudeAPI makes a request to Claude API
func (h *ClaudeHandler) callClaudeAPI(messages []map[string]interface{}) (string, error) {
	if h.claudeAPIKey == "" {
		return "", fmt.Errorf("Claude API key not configured")
	}

	payload := map[string]interface{}{
		"model":      "claude-3-5-sonnet-20241022",
		"max_tokens": 1024,
		"messages":   messages,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", "https://api.anthropic.com/v1/messages", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("x-api-key", h.claudeAPIKey)
	req.Header.Set("anthropic-version", "2023-06-01")
	req.Header.Set("Content-Type", "application/json")

	resp, err := h.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to call Claude API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("Claude API error: %s - %s", resp.Status, string(body))
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	// Extract text from response
	if content, ok := result["content"].([]interface{}); ok && len(content) > 0 {
		if textBlock, ok := content[0].(map[string]interface{}); ok {
			if text, ok := textBlock["text"].(string); ok {
				return text, nil
			}
		}
	}

	return "", fmt.Errorf("unexpected response format from Claude API")
}

// ParseTask parses natural language into a structured task
func (h *ClaudeHandler) ParseTask(c *gin.Context) {
	var req models.ParseTaskRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	prompt := fmt.Sprintf(`Parse the following natural language input into a structured task. Return a JSON object with:
- title: string (required)
- description: string (optional)
- due_date: ISO 8601 datetime string (if mentioned)
- priority: integer 1-5 (1=low, 5=high, default 3)
- category: string (optional, e.g., "work", "personal", "health")

Input: "%s"

Return ONLY valid JSON, no other text.`, req.Input)

	messages := []map[string]interface{}{
		{
			"role":    "user",
			"content": prompt,
		},
	}

	text, err := h.callClaudeAPI(messages)
	if err != nil {
		// Fallback to simple parsing if Claude API fails
		response := models.ParseTaskResponse{
			Task: &models.Task{
				Title:  req.Input,
				UserID: req.UserID,
			},
			Confidence:  0.5,
			Explanation: fmt.Sprintf("Fallback parsing (Claude API error: %v)", err),
		}
		c.JSON(http.StatusOK, response)
		return
	}

	// Parse Claude's JSON response
	var parsedTask map[string]interface{}
	if err := json.Unmarshal([]byte(text), &parsedTask); err != nil {
		// If JSON parsing fails, use fallback
		response := models.ParseTaskResponse{
			Task: &models.Task{
				Title:  req.Input,
				UserID: req.UserID,
			},
			Confidence:  0.6,
			Explanation: fmt.Sprintf("Parsed with Claude but JSON decode failed: %v", err),
		}
		c.JSON(http.StatusOK, response)
		return
	}

	// Build task from parsed data
	task := &models.Task{
		UserID: req.UserID,
	}
	if title, ok := parsedTask["title"].(string); ok {
		task.Title = title
	} else {
		task.Title = req.Input
	}
	if desc, ok := parsedTask["description"].(string); ok {
		task.Description = desc
	}
	if priority, ok := parsedTask["priority"].(float64); ok {
		task.Priority = int(priority)
	} else {
		task.Priority = 3
	}
	if category, ok := parsedTask["category"].(string); ok {
		task.Category = category
	}
	if dueDateStr, ok := parsedTask["due_date"].(string); ok {
		if dueDate, err := time.Parse(time.RFC3339, dueDateStr); err == nil {
			task.DueDate = dueDate
		}
	}

	response := models.ParseTaskResponse{
		Task:        task,
		Confidence:  0.9,
		Explanation: "Successfully parsed task using Claude AI",
	}

	c.JSON(http.StatusOK, response)
}

// ParseFile parses a file and extracts task data
func (h *ClaudeHandler) ParseFile(c *gin.Context) {
	var req models.ParseFileRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	prompt := fmt.Sprintf(`Parse the following file content and extract tasks, dates, and priorities. Return a JSON object with:
- tasks: array of task objects, each with title, description, due_date (ISO 8601), priority (1-5), category
- extracted_data: object with any other relevant information
- summary: string summary of the file

File Name: %s
File Type: %s
File Content:
%s

Return ONLY valid JSON, no other text.`, req.FileName, req.FileType, req.FileContent)

	messages := []map[string]interface{}{
		{
			"role":    "user",
			"content": prompt,
		},
	}

	text, err := h.callClaudeAPI(messages)
	if err != nil {
		response := models.ParseFileResponse{
			Tasks:         []models.Task{},
			ExtractedData: map[string]interface{}{},
			Summary:       fmt.Sprintf("File parsing failed: %v", err),
		}
		c.JSON(http.StatusOK, response)
		return
	}

	var parsed map[string]interface{}
	if err := json.Unmarshal([]byte(text), &parsed); err != nil {
		response := models.ParseFileResponse{
			Tasks:         []models.Task{},
			ExtractedData: map[string]interface{}{},
			Summary:       fmt.Sprintf("Failed to parse Claude response: %v", err),
		}
		c.JSON(http.StatusOK, response)
		return
	}

	// Extract tasks
	var tasks []models.Task
	if tasksArray, ok := parsed["tasks"].([]interface{}); ok {
		for _, t := range tasksArray {
			if taskMap, ok := t.(map[string]interface{}); ok {
				task := models.Task{UserID: req.UserID}
				if title, ok := taskMap["title"].(string); ok {
					task.Title = title
				}
				if desc, ok := taskMap["description"].(string); ok {
					task.Description = desc
				}
				if priority, ok := taskMap["priority"].(float64); ok {
					task.Priority = int(priority)
				}
				if category, ok := taskMap["category"].(string); ok {
					task.Category = category
				}
				if dueDateStr, ok := taskMap["due_date"].(string); ok {
					if dueDate, err := time.Parse(time.RFC3339, dueDateStr); err == nil {
						task.DueDate = dueDate
					}
				}
				tasks = append(tasks, task)
			}
		}
	}

	extractedData := map[string]interface{}{}
	if data, ok := parsed["extracted_data"].(map[string]interface{}); ok {
		extractedData = data
	}

	summary := "File parsed successfully"
	if s, ok := parsed["summary"].(string); ok {
		summary = s
	}

	response := models.ParseFileResponse{
		Tasks:         tasks,
		ExtractedData: extractedData,
		Summary:       summary,
	}

	c.JSON(http.StatusOK, response)
}

// GenerateSubtasks generates subtasks for a task using Claude
func (h *ClaudeHandler) GenerateSubtasks(c *gin.Context) {
	var req models.GenerateSubtasksRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	prompt := fmt.Sprintf(`Generate 3-7 actionable subtasks for the following task. Return a JSON array of strings, each string being a subtask.

Task Title: "%s"
Task Description: "%s"

Return ONLY a JSON array of strings, no other text. Example: ["Subtask 1", "Subtask 2", "Subtask 3"]`, req.TaskTitle, req.TaskDescription)

	messages := []map[string]interface{}{
		{
			"role":    "user",
			"content": prompt,
		},
	}

	text, err := h.callClaudeAPI(messages)
	if err != nil {
		// Fallback to default subtasks
		response := models.GenerateSubtasksResponse{
			Subtasks: []string{
				"Break down the task into smaller steps",
				"Research and gather information",
				"Execute the main components",
			},
			Explanation: fmt.Sprintf("Fallback subtasks (Claude API error: %v)", err),
		}
		c.JSON(http.StatusOK, response)
		return
	}

	// Parse Claude's JSON response
	var subtasks []string
	if err := json.Unmarshal([]byte(text), &subtasks); err != nil {
		// If JSON parsing fails, use fallback
		response := models.GenerateSubtasksResponse{
			Subtasks: []string{
				"Break down the task into smaller steps",
				"Research and gather information",
				"Execute the main components",
			},
			Explanation: fmt.Sprintf("Fallback subtasks (JSON decode error: %v)", err),
		}
		c.JSON(http.StatusOK, response)
		return
	}

	response := models.GenerateSubtasksResponse{
		Subtasks:    subtasks,
		Explanation: fmt.Sprintf("Generated %d subtasks using Claude AI", len(subtasks)),
	}

	c.JSON(http.StatusOK, response)
}

// AnalyzeProductivity analyzes user productivity patterns
func (h *ClaudeHandler) AnalyzeProductivity(c *gin.Context) {
	var req models.AnalyzeProductivityRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Days == 0 {
		req.Days = 7 // Default to last 7 days
	}

	// Fetch user's tasks from Supabase
	supabaseClient, err := db.NewSupabaseClient(h.supabaseURL, h.supabaseKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to Supabase"})
		return
	}

	tasks, err := supabaseClient.GetUserTasks(req.UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to fetch tasks: %v", err)})
		return
	}

	// Filter tasks by date range
	cutoffDate := time.Now().AddDate(0, 0, -req.Days)
	var recentTasks []map[string]interface{}
	completedCount := 0
	totalCount := len(tasks)

	for _, task := range tasks {
		if createdAt, ok := task["created_at"].(string); ok {
			if created, err := time.Parse(time.RFC3339, createdAt); err == nil && created.After(cutoffDate) {
				recentTasks = append(recentTasks, task)
				if completed, ok := task["completed"].(bool); ok && completed {
					completedCount++
				}
			}
		}
	}

	// Prepare data for Claude
	tasksJSON, _ := json.Marshal(recentTasks)
	prompt := fmt.Sprintf(`Analyze the following productivity data and provide insights and recommendations. Return a JSON object with:
- insights: array of strings (3-5 insights)
- recommendations: array of strings (3-5 recommendations)

Tasks data (last %d days):
%s

Return ONLY valid JSON, no other text.`, req.Days, string(tasksJSON))

	messages := []map[string]interface{}{
		{
			"role":    "user",
			"content": prompt,
		},
	}

	var insights []string
	var recommendations []string

	text, err := h.callClaudeAPI(messages)
	if err == nil {
		var analysis map[string]interface{}
		if err := json.Unmarshal([]byte(text), &analysis); err == nil {
			if ins, ok := analysis["insights"].([]interface{}); ok {
				for _, i := range ins {
					if str, ok := i.(string); ok {
						insights = append(insights, str)
					}
				}
			}
			if rec, ok := analysis["recommendations"].([]interface{}); ok {
				for _, r := range rec {
					if str, ok := r.(string); ok {
						recommendations = append(recommendations, str)
					}
				}
			}
		}
	}

	// Fallback if Claude fails
	if len(insights) == 0 {
		insights = []string{
			"Analyzed productivity data",
			"Found patterns in task completion",
		}
	}
	if len(recommendations) == 0 {
		recommendations = []string{
			"Continue tracking your tasks",
			"Focus on completing high-priority items",
		}
	}

	completionRate := 0.0
	if totalCount > 0 {
		completionRate = float64(completedCount) / float64(totalCount)
	}

	response := models.AnalyzeProductivityResponse{
		CompletedTasks:  completedCount,
		TotalTasks:      totalCount,
		CompletionRate:  completionRate,
		Insights:        insights,
		Recommendations: recommendations,
	}

	c.JSON(http.StatusOK, response)
}
