package middleware

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/productivity/mcp-server/utils"
)

// RequestLogger logs HTTP requests
func RequestLogger(logger *utils.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		// Process request
		c.Next()

		// Calculate latency
		latency := time.Since(start)

		// Get request ID if set
		requestID := c.GetString("request_id")
		if requestID == "" {
			requestID = c.GetHeader("X-Request-ID")
		}

		// Log request
		logger.Info("HTTP request",
			map[string]interface{}{
				"method":      c.Request.Method,
				"path":        path,
				"query":       query,
				"status":      c.Writer.Status(),
				"latency_ms":  latency.Milliseconds(),
				"client_ip":   c.ClientIP(),
				"user_agent":  c.Request.UserAgent(),
				"request_id":  requestID,
				"user_id":     c.GetString("user_id"),
			},
		)

		// Log errors
		if c.Writer.Status() >= 400 {
			err := c.Errors.Last()
			if err != nil {
				logger.Error("HTTP request error", err.Err,
					map[string]interface{}{
						"method":     c.Request.Method,
						"path":       path,
						"status":     c.Writer.Status(),
						"request_id": requestID,
					},
				)
			}
		}
	}
}

// RequestID adds a request ID to the context
func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = generateRequestID()
		}
		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)
		c.Next()
	}
}

func generateRequestID() string {
	// Generate a random request ID
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		// Fallback to timestamp-based ID if random generation fails
		return fmt.Sprintf("%d-%d", time.Now().UnixNano(), time.Now().Unix())
	}
	return hex.EncodeToString(bytes)
}

// Recovery middleware with proper error logging
func Recovery(logger *utils.Logger) gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		requestID := c.GetString("request_id")
		logger.Error("Panic recovered",
			fmt.Errorf("%v", recovered),
			map[string]interface{}{
				"method":     c.Request.Method,
				"path":       c.Request.URL.Path,
				"request_id": requestID,
			},
		)

		c.JSON(500, gin.H{
			"error":      "Internal server error",
			"request_id": requestID,
		})
		c.Abort()
	})
}
