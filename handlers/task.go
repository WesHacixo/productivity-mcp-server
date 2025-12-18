package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/productivity/mcp-server/db"
	"github.com/productivity/mcp-server/models"
)

// TaskHandler handles task-related requests
type TaskHandler struct {
	supabaseClient *db.SupabaseClient
}

// NewTaskHandler creates a new task handler
func NewTaskHandler(supabaseURL, supabaseKey string) *TaskHandler {
	client, err := db.NewSupabaseClient(supabaseURL, supabaseKey)
	if err != nil {
		panic(err)
	}
	return &TaskHandler{
		supabaseClient: client,
	}
}

// getUserID gets user ID from context, query param, or header
func getUserID(c *gin.Context) string {
	// Try context first (set by auth middleware if present)
	if userID := c.GetString("user_id"); userID != "" {
		return userID
	}
	// Try query parameter
	if userID := c.Query("user_id"); userID != "" {
		return userID
	}
	// Try header
	return c.GetHeader("X-User-ID")
}

// CreateTask creates a new task
func (h *TaskHandler) CreateTask(c *gin.Context) {
	var req models.CreateTaskRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id required (provide via query param ?user_id=xxx, header X-User-ID, or context)"})
		return
	}

	// Convert request to map for Supabase
	taskData := map[string]interface{}{
		"title":              req.Title,
		"description":        req.Description,
		"priority":           req.Priority,
		"due_date":           req.DueDate.Format(time.RFC3339),
		"estimated_duration": req.EstimatedDuration,
		"category":           req.Category,
		"completed":          false,
		"created_at":         time.Now().Format(time.RFC3339),
		"updated_at":         time.Now().Format(time.RFC3339),
	}

	if req.RecurringFrequency != "" {
		taskData["recurring_frequency"] = req.RecurringFrequency
		taskData["recurring_interval"] = req.RecurringInterval
		if req.RecurringEndDate != nil {
			taskData["recurring_end_date"] = req.RecurringEndDate.Format(time.RFC3339)
		}
	}

	taskID, err := h.supabaseClient.CreateTask(userID, taskData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Fetch the created task
	taskMap, err := h.supabaseClient.GetTask(taskID)
	if err != nil {
		c.JSON(http.StatusCreated, gin.H{"id": taskID, "message": "Task created but could not fetch details"})
		return
	}

	c.JSON(http.StatusCreated, taskMap)
}

// ListTasks lists all tasks
func (h *TaskHandler) ListTasks(c *gin.Context) {
	userID := getUserID(c)
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id required"})
		return
	}

	tasks, err := h.supabaseClient.GetUserTasks(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, tasks)
}

// GetTask gets a specific task
func (h *TaskHandler) GetTask(c *gin.Context) {
	taskID := c.Param("id")

	task, err := h.supabaseClient.GetTask(taskID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
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

	// Build update map from non-nil fields
	updateData := map[string]interface{}{
		"updated_at": time.Now().Format(time.RFC3339),
	}

	if req.Title != nil {
		updateData["title"] = *req.Title
	}
	if req.Description != nil {
		updateData["description"] = *req.Description
	}
	if req.Priority != nil {
		updateData["priority"] = *req.Priority
	}
	if req.DueDate != nil {
		updateData["due_date"] = req.DueDate.Format(time.RFC3339)
	}
	if req.EstimatedDuration != nil {
		updateData["estimated_duration"] = *req.EstimatedDuration
	}
	if req.Category != nil {
		updateData["category"] = *req.Category
	}
	if req.Completed != nil {
		updateData["completed"] = *req.Completed
		if *req.Completed {
			now := time.Now()
			updateData["completed_at"] = now.Format(time.RFC3339)
		} else {
			updateData["completed_at"] = nil
		}
	}
	if req.RecurringFrequency != nil {
		updateData["recurring_frequency"] = *req.RecurringFrequency
	}
	if req.RecurringInterval != nil {
		updateData["recurring_interval"] = *req.RecurringInterval
	}
	if req.RecurringEndDate != nil {
		updateData["recurring_end_date"] = req.RecurringEndDate.Format(time.RFC3339)
	}

	if err := h.supabaseClient.UpdateTask(taskID, updateData); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Fetch updated task
	task, err := h.supabaseClient.GetTask(taskID)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"id": taskID, "updated": true})
		return
	}

	c.JSON(http.StatusOK, task)
}

// DeleteTask deletes a task
func (h *TaskHandler) DeleteTask(c *gin.Context) {
	taskID := c.Param("id")

	if err := h.supabaseClient.DeleteTask(taskID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"id": taskID, "deleted": true})
}

// GetUserTasks gets all tasks for a user
func (h *TaskHandler) GetUserTasks(c *gin.Context) {
	userID := c.Param("userId")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id parameter required"})
		return
	}

	tasks, err := h.supabaseClient.GetUserTasks(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, tasks)
}
