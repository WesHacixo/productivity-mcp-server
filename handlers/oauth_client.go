package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// OAuthClient represents a registered OAuth client
type OAuthClient struct {
	ClientID     string   `json:"client_id"`
	ClientSecret string   `json:"client_secret,omitempty"`
	RedirectURIs []string `json:"redirect_uris"`
	Name         string   `json:"name,omitempty"`
}

// Default clients for development/testing
var defaultClients = map[string]*OAuthClient{
	"claude-desktop": {
		ClientID:     "claude-desktop",
		ClientSecret: "claude-desktop-secret-dev", // In production, use sealed variable
		RedirectURIs: []string{
			"http://localhost",
			"https://claude.ai",
			"claude://oauth-callback",
		},
		Name: "Claude Desktop",
	},
	"mcp_client": {
		ClientID:     "mcp_client",
		ClientSecret: "mcp_client_secret_dev", // In production, use sealed variable
		RedirectURIs: []string{
			"http://localhost",
			"https://example.com",
		},
		Name: "MCP Client",
	},
}

// OAuthRegister handles OAuth client registration
// POST /oauth/register
func OAuthRegister(c *gin.Context) {
	var req struct {
		ClientID     string   `json:"client_id"`
		ClientSecret string   `json:"client_secret,omitempty"`
		RedirectURIs []string `json:"redirect_uris"`
		Name         string   `json:"name,omitempty"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": err.Error(),
		})
		return
	}

	if req.ClientID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":             "invalid_request",
			"error_description": "client_id is required",
		})
		return
	}

	// TODO: Store in database
	// For now, return success (clients stored in memory)
	client := &OAuthClient{
		ClientID:     req.ClientID,
		ClientSecret: req.ClientSecret,
		RedirectURIs: req.RedirectURIs,
		Name:         req.Name,
	}

	// Store in default clients map (temporary - should use database)
	if defaultClients == nil {
		defaultClients = make(map[string]*OAuthClient)
	}
	defaultClients[req.ClientID] = client

	c.JSON(http.StatusCreated, gin.H{
		"client_id":     client.ClientID,
		"client_secret": client.ClientSecret,
		"redirect_uris": client.RedirectURIs,
		"name":          client.Name,
	})
}

// validateClient validates a client_id and client_secret
func validateClient(clientID, clientSecret string) bool {
	// Check default clients
	if client, ok := defaultClients[clientID]; ok {
		if clientSecret == "" || client.ClientSecret == clientSecret {
			return true
		}
	}
	return false
}

// validateRedirectURI validates redirect_uri against registered clients
func validateRedirectURI(clientID, redirectURI string) bool {
	if client, ok := defaultClients[clientID]; ok {
		for _, uri := range client.RedirectURIs {
			if uri == redirectURI {
				return true
			}
		}
	}
	// For development, allow common redirect URIs
	commonURIs := []string{
		"http://localhost",
		"https://claude.ai",
		"claude://oauth-callback",
		"https://example.com",
	}
	for _, uri := range commonURIs {
		if redirectURI == uri || redirectURI == uri+"/callback" {
			return true
		}
	}
	return false
}
