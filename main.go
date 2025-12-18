package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/productivity/mcp-server/handlers"
	"github.com/productivity/mcp-server/middleware"
	"github.com/productivity/mcp-server/utils"
)

func main() {
	// Load environment variables
	godotenv.Load()

	// Initialize logger
	logger := utils.NewLogger()
	logger.Info("Starting productivity MCP server")

	// Get configuration
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_ANON_KEY")
	claudeAPIKey := os.Getenv("CLAUDE_API_KEY")

	if supabaseURL == "" || supabaseKey == "" {
		logger.Error("Missing required environment variables", nil,
			map[string]interface{}{
				"supabase_url_set": supabaseURL != "",
				"supabase_key_set": supabaseKey != "",
			},
		)
		log.Fatal("Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables")
	}

	// Set Gin mode
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize Gin router
	router := gin.New()

	// Add recovery middleware with logging
	router.Use(middleware.Recovery(logger))

	// Add request ID middleware
	router.Use(middleware.RequestID())

	// Add request logging middleware
	router.Use(middleware.RequestLogger(logger))

	// Add CORS middleware
	router.Use(middleware.CORSMiddleware())

	// Enhanced health check endpoint
	router.GET("/health", func(c *gin.Context) {
		health := gin.H{
			"status":  "ok",
			"service": "productivity-mcp-server",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		}

		// Check dependencies
		deps := gin.H{}
		if supabaseURL != "" {
			deps["supabase"] = "configured"
		}
		if claudeAPIKey != "" {
			deps["claude"] = "configured"
		}
		health["dependencies"] = deps

		c.JSON(http.StatusOK, health)
	})

	// Readiness check (more detailed)
	router.GET("/ready", func(c *gin.Context) {
		ready := true
		checks := gin.H{}

		// Check Supabase connectivity (basic check)
		if supabaseURL == "" || supabaseKey == "" {
			ready = false
			checks["supabase"] = "not_configured"
		} else {
			checks["supabase"] = "configured"
		}

		status := http.StatusOK
		if !ready {
			status = http.StatusServiceUnavailable
		}

		c.JSON(status, gin.H{
			"ready":   ready,
			"checks":   checks,
			"timestamp": time.Now().UTC().Format(time.RFC3339),
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

	// OAuth 2.1 discovery endpoint (RFC 8414)
	router.GET("/.well-known/oauth-authorization-server", handlers.OAuthDiscovery)

	// OAuth 2.1 endpoints for MCP authentication
	// Support both /authorize and /oauth/authorize (common OAuth patterns)
	// #region agent log
	logger.Info("Registering OAuth routes", map[string]interface{}{
		"routes": []string{"/.well-known/oauth-authorization-server", "/authorize", "/oauth/authorize", "/oauth/token"},
	})
	// #endregion
	router.GET("/authorize", handlers.OAuthAuthorize)
	router.GET("/oauth/authorize", handlers.OAuthAuthorize)
	router.POST("/oauth/token", handlers.OAuthToken)
	router.POST("/oauth/introspect", handlers.OAuthIntrospect)
	router.POST("/oauth/register", handlers.OAuthRegister) // Client registration

	// MCP Protocol routes (protected with authentication)
	mcpHandler := handlers.NewMCPHandler(taskHandler, goalHandler, claudeHandler)
	mcpGroup := router.Group("/mcp")
	mcpGroup.Use(middleware.AuthMiddleware()) // Require authentication for MCP endpoints
	{
		mcpGroup.POST("/initialize", handlers.MCPInitialize)
		mcpGroup.POST("/call_tool", mcpHandler.MCPCallTool)
		mcpGroup.POST("/list_tools", handlers.MCPListTools)
	}

	// Create HTTP server with timeouts
	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		logger.Info("Server starting",
			map[string]interface{}{
				"port": port,
				"mode": gin.Mode(),
			},
		)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("Server failed to start", err,
				map[string]interface{}{
					"port": port,
				},
			)
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal for graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Error("Server forced to shutdown", err)
		log.Fatal("Server forced to shutdown:", err)
	}

	logger.Info("Server exited gracefully")
}
