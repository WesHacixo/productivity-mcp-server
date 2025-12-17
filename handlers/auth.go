package handlers

import (
	"crypto/rand"
	"encoding/base64"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret = getJWTSecret()

func getJWTSecret() []byte {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		// Generate a random secret for development (NOT for production!)
		secret = "dev-secret-change-in-production"
	}
	return []byte(secret)
}

// OAuthTokenRequest represents an OAuth token request
type OAuthTokenRequest struct {
	GrantType    string `json:"grant_type" binding:"required"`
	Code         string `json:"code,omitempty"`
	RefreshToken string `json:"refresh_token,omitempty"`
	ClientID     string `json:"client_id,omitempty"`
	ClientSecret string `json:"client_secret,omitempty"`
}

// OAuthTokenResponse represents an OAuth token response
type OAuthTokenResponse struct {
	AccessToken  string `json:"access_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int    `json:"expires_in"`
	RefreshToken string `json:"refresh_token,omitempty"`
	Scope        string `json:"scope,omitempty"`
}

// OAuthAuthorize handles OAuth authorization endpoint
// GET /oauth/authorize?client_id=xxx&redirect_uri=xxx&response_type=code&scope=xxx&state=xxx
func OAuthAuthorize(c *gin.Context) {
	clientID := c.Query("client_id")
	redirectURI := c.Query("redirect_uri")
	responseType := c.Query("response_type")
	_ = c.Query("scope") // scope - stored for future use
	state := c.Query("state")

	// Validate required parameters
	if clientID == "" || redirectURI == "" || responseType != "code" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "Missing required parameters",
		})
		return
	}

	// TODO: Validate client_id against registered clients
	// TODO: Validate redirect_uri
	// TODO: Check if user is authenticated (if not, redirect to login)

	// For now, generate an authorization code
	// In production, this should:
	// 1. Show a consent screen
	// 2. Require user authentication
	// 3. Generate a secure, short-lived authorization code
	authCode := generateAuthCode(clientID, redirectURI)

	// Redirect back with authorization code
	redirectURL := redirectURI + "?code=" + authCode + "&state=" + state
	c.Redirect(http.StatusFound, redirectURL)
}

// OAuthToken handles OAuth token endpoint
// POST /oauth/token
func OAuthToken(c *gin.Context) {
	var req OAuthTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": err.Error(),
		})
		return
	}

	switch req.GrantType {
	case "authorization_code":
		// Exchange authorization code for access token
		if req.Code == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_request",
				"error_description": "code is required",
			})
			return
		}

		// TODO: Validate authorization code
		// TODO: Check code hasn't been used
		// TODO: Verify client_id and client_secret

		// Generate access token
		accessToken, err := generateAccessToken(req.Code)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_grant",
				"error_description": "Invalid authorization code",
			})
			return
		}

		refreshToken := generateRefreshToken()

		c.JSON(http.StatusOK, OAuthTokenResponse{
			AccessToken:  accessToken,
			TokenType:    "Bearer",
			ExpiresIn:    3600, // 1 hour
			RefreshToken: refreshToken,
			Scope:        "read write",
		})

	case "refresh_token":
		// Refresh access token
		if req.RefreshToken == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_request",
				"error_description": "refresh_token is required",
			})
			return
		}

		// TODO: Validate refresh token
		// TODO: Check if refresh token is expired/revoked

		accessToken, err := refreshAccessToken(req.RefreshToken)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_grant",
				"error_description": "Invalid refresh token",
			})
			return
		}

		c.JSON(http.StatusOK, OAuthTokenResponse{
			AccessToken: accessToken,
			TokenType:   "Bearer",
			ExpiresIn:   3600,
		})

	default:
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "unsupported_grant_type",
			"error_description": "Grant type not supported",
		})
	}
}

// OAuthIntrospect handles token introspection endpoint
// POST /oauth/introspect
func OAuthIntrospect(c *gin.Context) {
	token := c.PostForm("token")
	if token == "" {
		// Try JSON body
		var req struct {
			Token string `json:"token"`
		}
		if err := c.ShouldBindJSON(&req); err == nil {
			token = req.Token
		}
	}

	if token == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"active": false,
		})
		return
	}

	// Validate token
	claims, err := validateJWT(token)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"active": false,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"active":    true,
		"client_id": claims["client_id"],
		"scope":     claims["scope"],
		"exp":       claims["exp"],
		"iat":       claims["iat"],
	})
}

// Helper functions

func generateAuthCode(clientID, redirectURI string) string {
	// Generate secure, random authorization code
	// TODO: Store in database/cache with expiration (10 minutes)
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return base64.URLEncoding.EncodeToString(bytes)
}

func generateAccessToken(authCode string) (string, error) {
	// TODO: Validate authCode and get user info from database/cache
	// For now, generate a JWT token with placeholder user ID
	// In production, look up authCode in database to get user_id

	claims := jwt.MapClaims{
		"sub":       "user_id_from_authcode", // TODO: Get from authCode lookup
		"client_id": "mcp_client",
		"scope":     "read write",
		"iat":       time.Now().Unix(),
		"exp":       time.Now().Add(time.Hour).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

func generateRefreshToken() string {
	// Generate secure, random refresh token
	// TODO: Store in database with expiration (30 days)
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return base64.URLEncoding.EncodeToString(bytes)
}

func refreshAccessToken(refreshToken string) (string, error) {
	// TODO: Validate refresh token
	// TODO: Get user info from refresh token
	// Generate new access token
	return generateAccessToken("")
}

func validateJWT(tokenString string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, jwt.ErrSignatureInvalid
}
