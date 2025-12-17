package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/productivity/mcp-server/db"
	"github.com/productivity/mcp-server/models"
)

// GoalHandler handles goal-related requests
type GoalHandler struct {
	supabaseClient *db.SupabaseClient
}

// NewGoalHandler creates a new goal handler
func NewGoalHandler(supabaseURL, supabaseKey string) *GoalHandler {
	client, err := db.NewSupabaseClient(supabaseURL, supabaseKey)
	if err != nil {
		panic(err)
	}
	return &GoalHandler{
		supabaseClient: client,
	}
}

// CreateGoal creates a new goal
func (h *GoalHandler) CreateGoal(c *gin.Context) {
	var req models.CreateGoalRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := getUserID(c)
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id required"})
		return
	}

	// Convert request to map for Supabase
	goalData := map[string]interface{}{
		"title":       req.Title,
		"description": req.Description,
		"start_date":  req.StartDate.Format(time.RFC3339),
		"target_date": req.TargetDate.Format(time.RFC3339),
		"progress":    req.Progress,
		"archived":    false,
		"created_at":  time.Now().Format(time.RFC3339),
		"updated_at":  time.Now().Format(time.RFC3339),
	}

	goalID, err := h.supabaseClient.CreateGoal(userID, goalData)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Fetch the created goal
	goalMap, err := h.supabaseClient.GetGoal(goalID)
	if err != nil {
		c.JSON(http.StatusCreated, gin.H{"id": goalID, "message": "Goal created but could not fetch details"})
		return
	}

	c.JSON(http.StatusCreated, goalMap)
}

// ListGoals lists all goals
func (h *GoalHandler) ListGoals(c *gin.Context) {
	userID := getUserID(c)
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id required"})
		return
	}

	goals, err := h.supabaseClient.GetUserGoals(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, goals)
}

// GetGoal gets a specific goal
func (h *GoalHandler) GetGoal(c *gin.Context) {
	goalID := c.Param("id")

	goal, err := h.supabaseClient.GetGoal(goalID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, goal)
}

// UpdateGoal updates a goal
func (h *GoalHandler) UpdateGoal(c *gin.Context) {
	goalID := c.Param("id")
	var req models.UpdateGoalRequest

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
	if req.StartDate != nil {
		updateData["start_date"] = req.StartDate.Format(time.RFC3339)
	}
	if req.TargetDate != nil {
		updateData["target_date"] = req.TargetDate.Format(time.RFC3339)
	}
	if req.Progress != nil {
		updateData["progress"] = *req.Progress
	}
	if req.Archived != nil {
		updateData["archived"] = *req.Archived
	}

	if err := h.supabaseClient.UpdateGoal(goalID, updateData); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Fetch updated goal
	goal, err := h.supabaseClient.GetGoal(goalID)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"id": goalID, "updated": true})
		return
	}

	c.JSON(http.StatusOK, goal)
}

// DeleteGoal deletes a goal
func (h *GoalHandler) DeleteGoal(c *gin.Context) {
	goalID := c.Param("id")

	if err := h.supabaseClient.DeleteGoal(goalID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"id": goalID, "deleted": true})
}

// GetUserGoals gets all goals for a user
func (h *GoalHandler) GetUserGoals(c *gin.Context) {
	userID := c.Param("userId")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id parameter required"})
		return
	}

	goals, err := h.supabaseClient.GetUserGoals(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, goals)
}
