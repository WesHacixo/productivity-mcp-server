package handlers

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestCaptureHandlerResponse(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(recorder)
	ctx.Request = httptest.NewRequest(http.MethodGet, "/mcp", nil)

	statusCode, body := captureHandlerResponse(ctx, func(c *gin.Context) {
		c.JSON(http.StatusCreated, gin.H{"ok": true})
	})

	if statusCode != http.StatusCreated {
		t.Fatalf("expected status 201, got %d", statusCode)
	}

	if len(body) == 0 {
		t.Fatalf("expected non-empty body")
	}
}
