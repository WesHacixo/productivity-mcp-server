package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/productivity/mcp-server/models"
)

// GoalHandler handles goal-related requests
type GoalHandler struct {
	supabaseURL string
	supabaseKey string
}

// NewGoalHandler creates a new goal handler
func NewGoalHandler(supabaseURL, supabaseKey string) *GoalHandler {
	return &GoalHandler{
		supabaseURL: supabaseURL,
		supabaseKey: supabaseKey,
	}
}

// CreateGoal creates a new goal
func (h *GoalHandler) CreateGoal(c *gin.Context) {
	var req models.CreateGoalRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user ID from context
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found in context"})
		return
	}

	// Create goal
	goal := models.Goal{
		UserID:      userID,
		Title:       req.Title,
		Description: req.Description,
		StartDate:   req.StartDate,
		TargetDate:  req.TargetDate,
		Progress:    req.Progress,
	}

	// TODO: Save to Supabase via REST API
	c.JSON(http.StatusCreated, goal)
}

// ListGoals lists all goals
func (h *GoalHandler) ListGoals(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user_id not found in context"})
		return
	}

	// TODO: Fetch from Supabase
	goals := []models.Goal{}
	c.JSON(http.StatusOK, goals)
}

// GetGoal gets a specific goal
func (h *GoalHandler) GetGoal(c *gin.Context) {
	goalID := c.Param("id")

	// TODO: Fetch from Supabase
	goal := models.Goal{
		ID: goalID,
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

	// TODO: Update in Supabase
	c.JSON(http.StatusOK, gin.H{"id": goalID, "updated": true})
}

// DeleteGoal deletes a goal
func (h *GoalHandler) DeleteGoal(c *gin.Context) {
	goalID := c.Param("id")

	// TODO: Delete from Supabase
	c.JSON(http.StatusOK, gin.H{"id": goalID, "deleted": true})
}

// GetUserGoals gets all goals for a user
func (h *GoalHandler) GetUserGoals(c *gin.Context) {
	_ = c.Param("userId") // TODO: Use for Supabase query

	// TODO: Fetch from Supabase
	goals := []models.Goal{}
	c.JSON(http.StatusOK, goals)
}
