package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/productivity/mcp-server/handlers"
	"github.com/productivity/mcp-server/middleware"
)

func main() {
	// Load environment variables
	godotenv.Load()

	// Get configuration
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_ANON_KEY")
	claudeAPIKey := os.Getenv("CLAUDE_API_KEY")

	if supabaseURL == "" || supabaseKey == "" {
		log.Fatal("Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables")
	}

	// Initialize Gin router
	router := gin.Default()

	// Add CORS middleware
	router.Use(middleware.CORSMiddleware())

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
			"service": "productivity-mcp-server",
		})
	})

	// Initialize handlers with dependencies
	taskHandler := handlers.NewTaskHandler(supabaseURL, supabaseKey)
	goalHandler := handlers.NewGoalHandler(supabaseURL, supabaseKey)
	claudeHandler := handlers.NewClaudeHandler(supabaseURL, supabaseKey, claudeAPIKey)

	// Task routes
	tasks := router.Group("/api/tasks")
	{
		tasks.POST("", taskHandler.CreateTask)
		tasks.GET("", taskHandler.ListTasks)
		tasks.GET("/:id", taskHandler.GetTask)
		tasks.PUT("/:id", taskHandler.UpdateTask)
		tasks.DELETE("/:id", taskHandler.DeleteTask)
		tasks.GET("/user/:userId", taskHandler.GetUserTasks)
	}

	// Goal routes
	goals := router.Group("/api/goals")
	{
		goals.POST("", goalHandler.CreateGoal)
		goals.GET("", goalHandler.ListGoals)
		goals.GET("/:id", goalHandler.GetGoal)
		goals.PUT("/:id", goalHandler.UpdateGoal)
		goals.DELETE("/:id", goalHandler.DeleteGoal)
		goals.GET("/user/:userId", goalHandler.GetUserGoals)
	}

	// Claude/MCP routes
	mcp := router.Group("/api/mcp")
	{
		mcp.POST("/parse-task", claudeHandler.ParseTask)
		mcp.POST("/parse-file", claudeHandler.ParseFile)
		mcp.POST("/generate-subtasks", claudeHandler.GenerateSubtasks)
		mcp.POST("/analyze-productivity", claudeHandler.AnalyzeProductivity)
	}

	// OAuth 2.0 endpoints for MCP authentication
	router.GET("/oauth/authorize", handlers.OAuthAuthorize)
	router.POST("/oauth/token", handlers.OAuthToken)
	router.POST("/oauth/introspect", handlers.OAuthIntrospect)

	// MCP Protocol routes (protected with authentication)
	mcpHandler := handlers.NewMCPHandler(taskHandler, goalHandler, claudeHandler)
	mcpGroup := router.Group("/mcp")
	mcpGroup.Use(middleware.AuthMiddleware()) // Require authentication for MCP endpoints
	{
		mcpGroup.POST("/initialize", handlers.MCPInitialize)
		mcpGroup.POST("/call_tool", mcpHandler.MCPCallTool)
		mcpGroup.POST("/list_tools", handlers.MCPListTools)
	}

	// Start server
	fmt.Printf("🚀 Productivity MCP Server running on port %s\n", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
