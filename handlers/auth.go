package handlers

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret = getJWTSecret()

const (
	// Token expiration constants
	AccessTokenExpiration  = 3600  // 1 hour in seconds
	RefreshTokenExpiration = 2592000 // 30 days in seconds
	AuthCodeExpiration     = 600    // 10 minutes in seconds
)

func getJWTSecret() []byte {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		// In production, this should be a fatal error
		if os.Getenv("GIN_MODE") == "release" {
			log.Fatal("JWT_SECRET environment variable is required in production mode")
		}
		// Generate a random secret for development only
		bytes := make([]byte, 32)
		if _, err := rand.Read(bytes); err != nil {
			log.Fatal("Failed to generate development JWT secret: ", err)
		}
		secret = base64.URLEncoding.EncodeToString(bytes)
		log.Println("⚠️  WARNING: Using auto-generated JWT secret for development. Set JWT_SECRET in production!")
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
	scope := c.Query("scope")
	state := c.Query("state")

	// Validate required parameters
	if clientID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "client_id is required",
		})
		return
	}

	if redirectURI == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "redirect_uri is required",
		})
		return
	}

	// Validate redirect_uri format
	parsedURI, err := url.Parse(redirectURI)
	if err != nil || !parsedURI.IsAbs() {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "redirect_uri must be a valid absolute URL",
		})
		return
	}

	// Only allow http/https schemes
	if parsedURI.Scheme != "http" && parsedURI.Scheme != "https" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "redirect_uri must use http or https scheme",
		})
		return
	}

	if responseType != "code" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "unsupported_response_type",
			"error_description": "Only 'code' response_type is supported",
		})
		return
	}

	// Validate state parameter (CSRF protection)
	if state == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "state parameter is required for CSRF protection",
		})
		return
	}

	// Validate client_id (check default clients or database)
	if !validateClient(clientID, "") {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_client",
			"error_description": "Unknown client_id. Use 'claude-desktop' or 'mcp_client' for development, or register a new client via /oauth/register",
		})
		return
	}

	// Validate redirect_uri
	if !validateRedirectURI(clientID, redirectURI) {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "redirect_uri not registered for this client",
		})
		return
	}
	// TODO: Check if user is authenticated (if not, redirect to login)

	// Generate an authorization code
	authCode, err := generateAuthCode(clientID, redirectURI)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":             "server_error",
			"error_description": "Failed to generate authorization code",
		})
		return
	}

	// Build redirect URL with proper encoding
	redirectURL, err := url.Parse(redirectURI)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "Invalid redirect_uri",
		})
		return
	}

	q := redirectURL.Query()
	q.Set("code", authCode)
	q.Set("state", state)
	if scope != "" {
		q.Set("scope", scope)
	}
	redirectURL.RawQuery = q.Encode()

	c.Redirect(http.StatusFound, redirectURL.String())
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

		// Validate client_id and client_secret if provided
		if req.ClientID != "" {
			if !validateClient(req.ClientID, req.ClientSecret) {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":             "invalid_client",
					"error_description": "Invalid client_id or client_secret",
				})
				return
			}
		}

		// TODO: Validate authorization code against database/cache
		// TODO: Check code hasn't been used (one-time use)
		// TODO: Check code hasn't expired
		// TODO: Verify redirect_uri matches the one used in authorization

		// Generate access token
		accessToken, err := generateAccessToken(req.Code)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_grant",
				"error_description": fmt.Sprintf("Invalid authorization code: %v", err),
			})
			return
		}

		refreshToken, err := generateRefreshToken()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":             "server_error",
				"error_description": "Failed to generate refresh token",
			})
			return
		}

		c.JSON(http.StatusOK, OAuthTokenResponse{
			AccessToken:  accessToken,
			TokenType:    "Bearer",
			ExpiresIn:    AccessTokenExpiration,
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

		// TODO: Validate refresh token against database
		// TODO: Check if refresh token is expired
		// TODO: Check if refresh token is revoked
		// TODO: Implement refresh token rotation (optional but recommended)

		accessToken, err := refreshAccessToken(req.RefreshToken)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_grant",
				"error_description": fmt.Sprintf("Invalid refresh token: %v", err),
			})
			return
		}

		c.JSON(http.StatusOK, OAuthTokenResponse{
			AccessToken: accessToken,
			TokenType:   "Bearer",
			ExpiresIn:   AccessTokenExpiration,
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

func generateAuthCode(clientID, redirectURI string) (string, error) {
	// Generate secure, random authorization code
	// TODO: Store in database/cache with expiration (AuthCodeExpiration)
	// Should store: code, client_id, redirect_uri, user_id, scope, expires_at
	
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", fmt.Errorf("failed to generate authorization code: %w", err)
	}
	
	code := base64.URLEncoding.EncodeToString(bytes)
	
	// TODO: Store code in database/cache:
	// - code: the generated code
	// - client_id: for validation
	// - redirect_uri: must match on token exchange
	// - user_id: from authenticated session
	// - scope: requested scope
	// - expires_at: time.Now().Add(AuthCodeExpiration * time.Second)
	// - used: false (set to true when exchanged)
	
	return code, nil
}

func generateAccessToken(authCode string) (string, error) {
	// TODO: Validate authCode and get user info from database/cache
	// For now, generate a JWT token with placeholder user ID
	// In production, look up authCode in database to get user_id
	
	// Validate authCode is not empty (basic validation)
	if authCode == "" {
		return "", fmt.Errorf("authorization code cannot be empty")
	}

	// TODO: Look up authCode in database/cache to get:
	// - user_id
	// - client_id
	// - scope
	// - Validate code hasn't been used and isn't expired

	claims := jwt.MapClaims{
		"sub":       "user_id_from_authcode", // TODO: Get from authCode lookup
		"client_id": "mcp_client",            // TODO: Get from authCode lookup
		"scope":     "read write",            // TODO: Get from authCode lookup
		"iat":       time.Now().Unix(),
		"exp":       time.Now().Add(time.Duration(AccessTokenExpiration) * time.Second).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

func generateRefreshToken() (string, error) {
	// Generate secure, random refresh token
	// TODO: Store in database with expiration (RefreshTokenExpiration)
	// Should store: token, user_id, client_id, scope, expires_at, revoked
	
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", fmt.Errorf("failed to generate refresh token: %w", err)
	}
	
	token := base64.URLEncoding.EncodeToString(bytes)
	
	// TODO: Store refresh token in database:
	// - token: the generated token
	// - user_id: from the access token
	// - client_id: from the access token
	// - scope: from the access token
	// - expires_at: time.Now().Add(RefreshTokenExpiration * time.Second)
	// - revoked: false (set to true when revoked)
	// - created_at: time.Now()
	
	return token, nil
}

func refreshAccessToken(refreshToken string) (string, error) {
	// Validate refresh token is not empty
	if refreshToken == "" {
		return "", fmt.Errorf("refresh token cannot be empty")
	}

	// TODO: Validate refresh token against database/cache
	// TODO: Check if refresh token is expired or revoked
	// TODO: Get user info from refresh token lookup
	// TODO: Invalidate old refresh token (one-time use)

	// For now, generate a new access token
	// In production, we should:
	// 1. Look up refreshToken in database
	// 2. Verify it's valid and not expired
	// 3. Get user_id and client_id from the stored token
	// 4. Generate new access token with proper user info
	// 5. Optionally generate new refresh token (refresh token rotation)

	// Use refreshToken as a placeholder authCode for now
	// This is a temporary workaround until proper token storage is implemented
	return generateAccessToken(refreshToken)
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
