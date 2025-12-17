package middleware

import (
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware handles authentication for MCP endpoints
// Supports both OAuth Bearer tokens and API keys
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Extract token from Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"jsonrpc": "2.0",
				"id":      nil,
				"error": gin.H{
					"code":    -32001,
					"message": "Unauthorized: Missing Authorization header",
				},
			})
			c.Abort()
			return
		}

		// Parse Bearer token
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"jsonrpc": "2.0",
				"id":      nil,
				"error": gin.H{
					"code":    -32001,
					"message": "Unauthorized: Invalid Authorization header format. Expected 'Bearer <token>'",
				},
			})
			c.Abort()
			return
		}

		token := parts[1]
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"jsonrpc": "2.0",
				"id":      nil,
				"error": gin.H{
					"code":    -32001,
					"message": "Unauthorized: Empty token",
				},
			})
			c.Abort()
			return
		}

		// Validate token (implement your validation logic here)
		// For now, we'll store it in context for handlers to use
		// You can add JWT validation, OAuth token verification, etc.
		userID, err := validateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"jsonrpc": "2.0",
				"id":      nil,
				"error": gin.H{
					"code":    -32001,
					"message": "Unauthorized: " + err.Error(),
				},
			})
			c.Abort()
			return
		}

		// Store user info in context
		c.Set("user_id", userID)
		c.Set("auth_token", token)

		c.Next()
	}
}

// validateToken validates the bearer token and returns user ID
// Supports JWT tokens and OAuth access tokens
func validateToken(token string) (string, error) {
	// Try JWT validation first
	claims, err := validateJWT(token)
	if err == nil {
		// Extract user ID from JWT claims
		if userID, ok := claims["sub"].(string); ok {
			return userID, nil
		}
		if userID, ok := claims["user_id"].(string); ok {
			return userID, nil
		}
	}

	// TODO: Try OAuth token introspection
	// Call /oauth/introspect endpoint to validate OAuth token
	// This would be an internal call to validate the token

	// For now, if JWT validation fails, return error
	return "", err
}

// validateJWT validates a JWT token and returns claims
func validateJWT(tokenString string) (map[string]interface{}, error) {
	// Load JWT secret from environment variable
	secret := getJWTSecret()

	// Parse and validate JWT using github.com/golang-jwt/jwt/v5
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return secret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		// Check expiration
		if exp, ok := claims["exp"].(float64); ok {
			if time.Now().Unix() > int64(exp) {
				return nil, fmt.Errorf("token expired")
			}
		}
		return map[string]interface{}(claims), nil
	}

	return nil, fmt.Errorf("invalid token")
}

func getJWTSecret() []byte {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		// Generate a random secret for development (NOT for production!)
		secret = "dev-secret-change-in-production"
	}
	return []byte(secret)
}

// OptionalAuthMiddleware allows requests with or without auth
// Used for endpoints that can work with optional authentication
func OptionalAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				token := parts[1]
				if token != "" {
					userID, err := validateToken(token)
					if err == nil {
						c.Set("user_id", userID)
						c.Set("auth_token", token)
					}
				}
			}
		}
		c.Next()
	}
}
