package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/productivity/mcp-server/models"
)

// TaskHandler handles task-related requests
type TaskHandler struct {
	supabaseURL string
	supabaseKey string
}

// NewTaskHandler creates a new task handler
func NewTaskHandler(supabaseURL, supabaseKey string) *TaskHandler {
	return &TaskHandler{
		supabaseURL: supabaseURL,
		supabaseKey: supabaseKey,
	}
}

// CreateTask creates a new task
func (h *TaskHandler) CreateTask(c *gin.Context) {
	var req models.CreateTaskRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user ID from context (would be set by auth middleware)
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found in context"})
		return
	}

	// Create task in Supabase
	task := models.Task{
		UserID:            userID,
		Title:             req.Title,
		Description:       req.Description,
		Priority:          req.Priority,
		DueDate:           req.DueDate,
		EstimatedDuration: req.EstimatedDuration,
		Category:          req.Category,
	}

	// TODO: Save to Supabase via REST API
	c.JSON(http.StatusCreated, task)
}

// ListTasks lists all tasks
func (h *TaskHandler) ListTasks(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found in context"})
		return
	}

	// TODO: Fetch from Supabase
	tasks := []models.Task{}
	c.JSON(http.StatusOK, tasks)
}

// GetTask gets a specific task
func (h *TaskHandler) GetTask(c *gin.Context) {
	taskID := c.Param("id")

	// TODO: Fetch from Supabase
	task := models.Task{
		ID: taskID,
	}

	c.JSON(http.StatusOK, task)
}

// UpdateTask updates a task
func (h *TaskHandler) UpdateTask(c *gin.Context) {
	taskID := c.Param("id")
	var req models.UpdateTaskRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Update in Supabase
	c.JSON(http.StatusOK, gin.H{"id": taskID, "updated": true})
}

// DeleteTask deletes a task
func (h *TaskHandler) DeleteTask(c *gin.Context) {
	taskID := c.Param("id")

	// TODO: Delete from Supabase
	c.JSON(http.StatusOK, gin.H{"id": taskID, "deleted": true})
}

// GetUserTasks gets all tasks for a user
func (h *TaskHandler) GetUserTasks(c *gin.Context) {
	_ = c.Param("userId") // TODO: Use for Supabase query

	// TODO: Fetch from Supabase
	tasks := []models.Task{}
	c.JSON(http.StatusOK, tasks)
}
