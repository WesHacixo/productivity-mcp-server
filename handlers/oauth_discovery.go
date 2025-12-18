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

	discovery := map[string]interface{}{
		"issuer":                            baseURL,
		"authorization_endpoint":            baseURL + "/oauth/authorize",
		"token_endpoint":                    baseURL + "/oauth/token",
		"token_endpoint_auth_methods_supported": []string{"client_secret_post", "client_secret_basic"},
		"response_types_supported":          []string{"code"},
		"grant_types_supported":             []string{"authorization_code", "refresh_token"},
		"code_challenge_methods_supported": []string{"S256"}, // PKCE support
		"scopes_supported":                 []string{"read", "write", "mcp"},
		"response_modes_supported":         []string{"query"},
	}

	c.JSON(http.StatusOK, discovery)
}

// getBaseURL extracts the base URL from the request
func getBaseURL(c *gin.Context) string {
	scheme := "https"
	if c.GetHeader("X-Forwarded-Proto") != "" {
		scheme = c.GetHeader("X-Forwarded-Proto")
	} else if c.Request.TLS == nil {
		scheme = "http"
	}

	host := c.Request.Host
	if host == "" {
		host = "productivity-mcp-server-production.up.railway.app"
	}

	return scheme + "://" + host
}
