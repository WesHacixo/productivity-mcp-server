package handlers

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// #region agent log
func debugLog(location, message string, data map[string]interface{}) {
	logEntry := map[string]interface{}{
		"sessionId": "debug-session",
		"runId":     "run1",
		"location":  location,
		"message":   message,
		"data":      data,
		"timestamp": time.Now().UnixMilli(),
	}
	if logData, err := json.Marshal(logEntry); err == nil {
		// Use relative path or environment variable for log file
		logPath := os.Getenv("DEBUG_LOG_PATH")
		if logPath == "" {
			// Default to relative path (works in both local and Railway)
			logPath = ".cursor/debug.log"
		}
		if f, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644); err == nil {
			fmt.Fprintln(f, string(logData))
			f.Close()
		}
	}
}

// #endregion

var jwtSecret = getJWTSecret()

const (
	// Token expiration constants
	AccessTokenExpiration  = 3600    // 1 hour in seconds
	RefreshTokenExpiration = 2592000 // 30 days in seconds
	AuthCodeExpiration     = 600     // 10 minutes in seconds
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

// OAuthTokenRequest represents an OAuth token request (OAuth 2.1 with PKCE)
type OAuthTokenRequest struct {
	GrantType    string `json:"grant_type" binding:"required"`
	Code         string `json:"code,omitempty"`
	RefreshToken string `json:"refresh_token,omitempty"`
	ClientID     string `json:"client_id,omitempty"`
	ClientSecret string `json:"client_secret,omitempty"`
	CodeVerifier string `json:"code_verifier,omitempty"` // PKCE: code_verifier for token exchange
	RedirectURI  string `json:"redirect_uri,omitempty"`  // Must match the one used in authorization
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
// GET /oauth/authorize?client_id=xxx&redirect_uri=xxx&response_type=code&scope=xxx&state=xxx&code_challenge=xxx&code_challenge_method=S256
// Also handles GET /authorize (common OAuth pattern)
func OAuthAuthorize(c *gin.Context) {
	// #region agent log
	debugLog("auth.go:67", "OAuthAuthorize entry", map[string]interface{}{
		"path":         c.Request.URL.Path,
		"method":       c.Request.Method,
		"hypothesisId": "H2",
	})
	// #endregion

	clientID := c.Query("client_id")
	redirectURI := c.Query("redirect_uri")
	responseType := c.Query("response_type")
	scope := c.Query("scope")
	state := c.Query("state")
	codeChallenge := c.Query("code_challenge")
	codeChallengeMethod := c.Query("code_challenge_method")

	// #region agent log
	debugLog("auth.go:79", "OAuthAuthorize params extracted", map[string]interface{}{
		"clientID":            clientID,
		"redirectURI":         redirectURI,
		"responseType":        responseType,
		"hasState":            state != "",
		"hasCodeChallenge":    codeChallenge != "",
		"codeChallengeMethod": codeChallengeMethod,
		"hypothesisId":        "H2,H4",
	})
	// #endregion

	// Validate required parameters
	// OAuth 2.1: Errors should redirect to redirect_uri with error parameters (if redirect_uri is provided)
	// If redirect_uri is missing, we can't redirect, so return JSON error
	if clientID == "" {
		// #region agent log
		debugLog("auth.go:117", "OAuthAuthorize error: missing client_id", map[string]interface{}{
			"hasRedirectURI": redirectURI != "",
			"hypothesisId":   "H1",
		})
		// #endregion
		if redirectURI != "" {
			// Redirect with error (OAuth 2.1 spec)
			redirectURL, _ := url.Parse(redirectURI)
			if redirectURL != nil {
				q := redirectURL.Query()
				q.Set("error", "invalid_request")
				q.Set("error_description", "client_id is required")
				if state != "" {
					q.Set("state", state)
				}
				redirectURL.RawQuery = q.Encode()
				c.Redirect(http.StatusFound, redirectURL.String())
				return
			}
		}
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
		// #region agent log
		debugLog("auth.go:145", "OAuthAuthorize error: invalid redirect_uri format", map[string]interface{}{
			"redirectURI": redirectURI,
			"error": func() string {
				if err != nil {
					return err.Error()
				} else {
					return "not absolute"
				}
			}(),
			"hypothesisId": "H1",
		})
		// #endregion
		// Can't redirect to invalid URI per OAuth 2.1 spec (security)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "redirect_uri must be a valid absolute URL",
		})
		return
	}

	// Allow http/https schemes and custom schemes (e.g., claude://)
	// Custom schemes are allowed for native app redirects (OAuth 2.1 best practice)
	allowedSchemes := []string{"http", "https", "claude"}
	schemeAllowed := false
	for _, allowed := range allowedSchemes {
		if parsedURI.Scheme == allowed {
			schemeAllowed = true
			break
		}
	}
	if !schemeAllowed {
		// #region agent log
		debugLog("auth.go:164", "OAuthAuthorize error: invalid scheme", map[string]interface{}{
			"scheme":       parsedURI.Scheme,
			"redirectURI":  redirectURI,
			"hypothesisId": "H1",
		})
		// #endregion
		// Can't redirect to invalid URI per OAuth 2.1 spec (security)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": fmt.Sprintf("redirect_uri scheme '%s' not allowed. Allowed schemes: http, https, claude", parsedURI.Scheme),
		})
		return
	}

	if responseType != "code" {
		// #region agent log
		debugLog("auth.go:172", "OAuthAuthorize error: unsupported response_type", map[string]interface{}{
			"responseType": responseType,
			"hypothesisId": "H1",
		})
		// #endregion
		// Redirect with error (OAuth 2.1 spec)
		redirectURL, _ := url.Parse(redirectURI)
		if redirectURL != nil {
			q := redirectURL.Query()
			q.Set("error", "unsupported_response_type")
			q.Set("error_description", "Only 'code' response_type is supported")
			if state != "" {
				q.Set("state", state)
			}
			redirectURL.RawQuery = q.Encode()
			c.Redirect(http.StatusFound, redirectURL.String())
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "unsupported_response_type",
			"error_description": "Only 'code' response_type is supported",
		})
		return
	}

	// Validate state parameter (CSRF protection)
	if state == "" {
		// #region agent log
		debugLog("auth.go:190", "OAuthAuthorize error: missing state", map[string]interface{}{
			"hypothesisId": "H1",
		})
		// #endregion
		// Redirect with error (OAuth 2.1 spec)
		redirectURL, _ := url.Parse(redirectURI)
		if redirectURL != nil {
			q := redirectURL.Query()
			q.Set("error", "invalid_request")
			q.Set("error_description", "state parameter is required for CSRF protection")
			redirectURL.RawQuery = q.Encode()
			c.Redirect(http.StatusFound, redirectURL.String())
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "state parameter is required for CSRF protection",
		})
		return
	}

	// Validate client_id (check default clients or database)
	clientValid := validateClient(clientID, "")
	// #region agent log
	debugLog("auth.go:139", "Client validation result", map[string]interface{}{
		"clientID":     clientID,
		"valid":        clientValid,
		"hypothesisId": "H6",
	})
	// #endregion
	if !clientValid {
		// #region agent log
		debugLog("auth.go:210", "OAuthAuthorize error: invalid client", map[string]interface{}{
			"clientID":     clientID,
			"hypothesisId": "H1,H6",
		})
		// #endregion
		// Redirect with error (OAuth 2.1 spec)
		redirectURL, _ := url.Parse(redirectURI)
		if redirectURL != nil {
			q := redirectURL.Query()
			q.Set("error", "invalid_client")
			q.Set("error_description", "Unknown client_id")
			if state != "" {
				q.Set("state", state)
			}
			redirectURL.RawQuery = q.Encode()
			c.Redirect(http.StatusFound, redirectURL.String())
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_client",
			"error_description": "Unknown client_id. Use 'claude-desktop' or 'mcp_client' for development, or register a new client via /oauth/register",
		})
		return
	}

	// Validate redirect_uri
	redirectValid := validateRedirectURI(clientID, redirectURI)
	// #region agent log
	debugLog("auth.go:148", "Redirect URI validation result", map[string]interface{}{
		"clientID":     clientID,
		"redirectURI":  redirectURI,
		"valid":        redirectValid,
		"hypothesisId": "H6",
	})
	// #endregion
	if !redirectValid {
		// #region agent log
		debugLog("auth.go:235", "OAuthAuthorize error: invalid redirect_uri", map[string]interface{}{
			"clientID":     clientID,
			"redirectURI":  redirectURI,
			"hypothesisId": "H1,H6",
		})
		// #endregion
		// Can't redirect to invalid URI per OAuth 2.1 spec (security - prevents open redirect)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "redirect_uri not registered for this client",
		})
		return
	}

	// Validate PKCE parameters (OAuth 2.1 requirement)
	if codeChallenge != "" {
		if codeChallengeMethod == "" {
			codeChallengeMethod = "S256" // Default to S256 per OAuth 2.1
		}
		if codeChallengeMethod != "S256" && codeChallengeMethod != "plain" {
			// #region agent log
			debugLog("auth.go:252", "OAuthAuthorize error: invalid code_challenge_method", map[string]interface{}{
				"method":       codeChallengeMethod,
				"hypothesisId": "H1",
			})
			// #endregion
			// Redirect with error (OAuth 2.1 spec)
			redirectURL, _ := url.Parse(redirectURI)
			if redirectURL != nil {
				q := redirectURL.Query()
				q.Set("error", "invalid_request")
				q.Set("error_description", "code_challenge_method must be 'S256' or 'plain'")
				if state != "" {
					q.Set("state", state)
				}
				redirectURL.RawQuery = q.Encode()
				c.Redirect(http.StatusFound, redirectURL.String())
				return
			}
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_request",
				"error_description": "code_challenge_method must be 'S256' or 'plain'",
			})
			return
		}
		// Validate code_challenge format (base64url encoded, 43-128 chars for S256)
		if codeChallengeMethod == "S256" && (len(codeChallenge) < 43 || len(codeChallenge) > 128) {
			// #region agent log
			debugLog("auth.go:270", "OAuthAuthorize error: invalid code_challenge length", map[string]interface{}{
				"length":       len(codeChallenge),
				"method":       codeChallengeMethod,
				"hypothesisId": "H1",
			})
			// #endregion
			// Redirect with error (OAuth 2.1 spec)
			redirectURL, _ := url.Parse(redirectURI)
			if redirectURL != nil {
				q := redirectURL.Query()
				q.Set("error", "invalid_request")
				q.Set("error_description", "code_challenge must be 43-128 characters for S256 method")
				if state != "" {
					q.Set("state", state)
				}
				redirectURL.RawQuery = q.Encode()
				c.Redirect(http.StatusFound, redirectURL.String())
				return
			}
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_request",
				"error_description": "code_challenge must be 43-128 characters for S256 method",
			})
			return
		}
	}

	// TODO: Check if user is authenticated (if not, redirect to login)

	// Generate an authorization code
	authCode, err := generateAuthCode(clientID, redirectURI)
	// #region agent log
	debugLog("auth.go:181", "Auth code generation result", map[string]interface{}{
		"hasCode":  authCode != "",
		"hasError": err != nil,
		"error": func() string {
			if err != nil {
				return err.Error()
			} else {
				return ""
			}
		}(),
		"hypothesisId": "H4",
	})
	// #endregion
	if err != nil {
		// #region agent log
		debugLog("auth.go:187", "OAuthAuthorize error: failed to generate code", map[string]interface{}{
			"error":        err.Error(),
			"hypothesisId": "H1,H4",
		})
		// #endregion
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":             "server_error",
			"error_description": "Failed to generate authorization code",
		})
		return
	}

	// Store auth code with PKCE data (always store, even without PKCE for consistency)
	authCodeData := &AuthCodeData{
		Code:                authCode,
		ClientID:            clientID,
		RedirectURI:         redirectURI,
		CodeChallenge:       codeChallenge,
		CodeChallengeMethod: codeChallengeMethod,
		Scope:               scope,
		State:               state,
		ExpiresAt:           time.Now().Add(time.Duration(AuthCodeExpiration) * time.Second).Unix(),
		Used:                false,
	}
	StoreAuthCode(authCode, authCodeData)
	// #region agent log
	debugLog("auth.go:202", "Auth code stored", map[string]interface{}{
		"code":             authCode,
		"hasCodeChallenge": codeChallenge != "",
		"expiresAt":        authCodeData.ExpiresAt,
		"hypothesisId":     "H4",
	})
	// #endregion

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

	// #region agent log
	debugLog("auth.go:222", "OAuthAuthorize redirect", map[string]interface{}{
		"redirectURL":  redirectURL.String(),
		"statusCode":   302,
		"hypothesisId": "H2",
	})
	// #endregion

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
		// Exchange authorization code for access token (OAuth 2.1 with PKCE)
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

		// Get stored auth code data
		authCodeData, err := GetAuthCode(req.Code)
		// #region agent log
		debugLog("auth.go:260", "GetAuthCode result", map[string]interface{}{
			"code":  req.Code,
			"found": err == nil,
			"error": func() string {
				if err != nil {
					return err.Error()
				} else {
					return ""
				}
			}(),
			"hypothesisId": "H4",
		})
		// #endregion
		if err != nil {
			// #region agent log
			debugLog("auth.go:266", "OAuthToken error: invalid code", map[string]interface{}{
				"code":         req.Code,
				"error":        err.Error(),
				"hypothesisId": "H4",
			})
			// #endregion
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_grant",
				"error_description": fmt.Sprintf("Invalid or expired authorization code: %v", err),
			})
			return
		}

		// Check if code has expired
		if time.Now().Unix() > authCodeData.ExpiresAt {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_grant",
				"error_description": "Authorization code has expired",
			})
			return
		}

		// Validate redirect_uri matches (if provided)
		if req.RedirectURI != "" && req.RedirectURI != authCodeData.RedirectURI {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":             "invalid_grant",
				"error_description": "redirect_uri does not match the one used in authorization",
			})
			return
		}

		// Validate PKCE if code_challenge was provided during authorization
		if authCodeData.CodeChallenge != "" {
			if req.CodeVerifier == "" {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":             "invalid_request",
					"error_description": "code_verifier is required (PKCE was used in authorization)",
				})
				return
			}

			// Validate code_verifier against stored code_challenge
			pkceErr := ValidatePKCE(authCodeData.CodeChallenge, authCodeData.CodeChallengeMethod, req.CodeVerifier)
			// #region agent log
			debugLog("auth.go:298", "PKCE validation result", map[string]interface{}{
				"codeChallenge":   authCodeData.CodeChallenge,
				"method":          authCodeData.CodeChallengeMethod,
				"hasCodeVerifier": req.CodeVerifier != "",
				"valid":           pkceErr == nil,
				"error": func() string {
					if pkceErr != nil {
						return pkceErr.Error()
					} else {
						return ""
					}
				}(),
				"hypothesisId": "H5",
			})
			// #endregion
			if pkceErr != nil {
				// #region agent log
				debugLog("auth.go:303", "OAuthToken error: PKCE validation failed", map[string]interface{}{
					"error":        pkceErr.Error(),
					"hypothesisId": "H5",
				})
				// #endregion
				c.JSON(http.StatusBadRequest, gin.H{
					"error":             "invalid_grant",
					"error_description": fmt.Sprintf("PKCE validation failed: %v", pkceErr),
				})
				return
			}
		}

		// Generate access token using data from auth code
		accessToken, err := generateAccessTokenFromAuthCode(authCodeData)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":             "server_error",
				"error_description": fmt.Sprintf("Failed to generate access token: %v", err),
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

		scope := authCodeData.Scope
		if scope == "" {
			scope = "read write"
		}

		c.JSON(http.StatusOK, OAuthTokenResponse{
			AccessToken:  accessToken,
			TokenType:    "Bearer",
			ExpiresIn:    AccessTokenExpiration,
			RefreshToken: refreshToken,
			Scope:        scope,
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

// generateAccessTokenFromAuthCode generates an access token from stored auth code data
func generateAccessTokenFromAuthCode(authCodeData *AuthCodeData) (string, error) {
	// TODO: Get actual user_id from database based on authenticated session
	// For now, use placeholder
	userID := "user_id_from_session" // TODO: Get from authCodeData or session

	claims := jwt.MapClaims{
		"sub":       userID,
		"client_id": authCodeData.ClientID,
		"scope":     authCodeData.Scope,
		"iat":       time.Now().Unix(),
		"exp":       time.Now().Add(time.Duration(AccessTokenExpiration) * time.Second).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// generateAccessToken is kept for backward compatibility
func generateAccessToken(authCode string) (string, error) {
	// This is deprecated - use generateAccessTokenFromAuthCode instead
	// But kept for refresh token flow
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
