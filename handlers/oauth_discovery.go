package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// OAuthDiscovery handles OAuth 2.0 discovery endpoint
// GET /.well-known/oauth-authorization-server
// Returns OAuth server metadata per RFC 8414
func OAuthDiscovery(c *gin.Context) {
	baseURL := getBaseURL(c)
	// #region agent log
	debugLog("oauth_discovery.go:13", "OAuthDiscovery entry", map[string]interface{}{
		"baseURL":      baseURL,
		"host":         c.Request.Host,
		"scheme":       c.Request.URL.Scheme,
		"hypothesisId": "H3",
	})
	// #endregion

	discovery := map[string]interface{}{
		"issuer":                                baseURL,
		"authorization_endpoint":                baseURL + "/authorize", // Claude Desktop calls /authorize
		"token_endpoint":                        baseURL + "/oauth/token",
		"token_endpoint_auth_methods_supported": []string{"client_secret_post", "client_secret_basic", "none"}, // OAuth 2.1: PKCE allows no client secret
		"response_types_supported":              []string{"code"},
		"grant_types_supported":                 []string{"authorization_code", "refresh_token"},
		"code_challenge_methods_supported":      []string{"S256", "plain"}, // OAuth 2.1: PKCE support (S256 required, plain optional)
		"scopes_supported":                      []string{"read", "write", "mcp", "claudeai"},
		"response_modes_supported":              []string{"query"},
		"revocation_endpoint":                   baseURL + "/oauth/revoke", // OAuth 2.1: Token revocation
	}

	c.JSON(http.StatusOK, discovery)
}

// getBaseURL extracts the base URL from the request
func getBaseURL(c *gin.Context) string {
	scheme := "https"
	forwardedProto := c.GetHeader("X-Forwarded-Proto")
	if forwardedProto != "" {
		scheme = forwardedProto
	} else if c.Request.TLS == nil {
		scheme = "http"
	}

	host := c.Request.Host
	if host == "" {
		host = "productivity-mcp-server-production.up.railway.app"
	}

	result := scheme + "://" + host
	// #region agent log
	debugLog("oauth_discovery.go:45", "getBaseURL result", map[string]interface{}{
		"result":         result,
		"host":           host,
		"scheme":         scheme,
		"forwardedProto": forwardedProto,
		"hasTLS":         c.Request.TLS != nil,
		"hypothesisId":   "H3",
	})
	// #endregion
	return result
}
