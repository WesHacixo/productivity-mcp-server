package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// OllamaHandler handles Ollama LLM integration
type OllamaHandler struct {
	ollamaURL  string
	modelName  string
	httpClient *http.Client
}

// NewOllamaHandler creates a new Ollama handler
func NewOllamaHandler(ollamaURL, modelName string) *OllamaHandler {
	if ollamaURL == "" {
		ollamaURL = "http://100.74.59.83:11434" // Mac Studio Tailscale IP
	}
	if modelName == "" {
		modelName = "qwen3-coder:480b-cloud"
	}

	return &OllamaHandler{
		ollamaURL:  ollamaURL,
		modelName:  modelName,
		httpClient: &http.Client{Timeout: 120 * time.Second}, // Longer timeout for large models
	}
}

// GenerateRequest represents an Ollama generate request
type GenerateRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
	Stream bool   `json:"stream"`
	System string `json:"system,omitempty"`
}

// GenerateResponse represents an Ollama generate response
type GenerateResponse struct {
	Model              string    `json:"model"`
	CreatedAt          time.Time `json:"created_at"`
	Response           string    `json:"response"`
	Done               bool      `json:"done"`
	Context            []int     `json:"context,omitempty"`
	TotalDuration      int64     `json:"total_duration,omitempty"`
	LoadDuration       int64     `json:"load_duration,omitempty"`
	PromptEvalCount    int       `json:"prompt_eval_count,omitempty"`
	PromptEvalDuration int64     `json:"prompt_eval_duration,omitempty"`
	EvalCount          int       `json:"eval_count,omitempty"`
	EvalDuration       int64     `json:"eval_duration,omitempty"`
}

// Generate sends a prompt to Ollama and returns the response
func (h *OllamaHandler) Generate(prompt string, systemPrompt string) (string, error) {
	req := GenerateRequest{
		Model:  h.modelName,
		Prompt: prompt,
		Stream: false,
	}
	if systemPrompt != "" {
		req.System = systemPrompt
	}

	jsonData, err := json.Marshal(req)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	resp, err := h.httpClient.Post(h.ollamaURL+"/api/generate", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("server returned status %d: %s", resp.StatusCode, string(body))
	}

	var genResp GenerateResponse
	if err := json.NewDecoder(resp.Body).Decode(&genResp); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if !genResp.Done {
		return "", fmt.Errorf("generation did not complete")
	}

	return genResp.Response, nil
}

// ReviewCodebaseRequest represents a codebase review request
type ReviewCodebaseRequest struct {
	BasePath     string   `json:"base_path"`
	FilePatterns []string `json:"file_patterns,omitempty"` // e.g., ["*.go", "*.ts", "*.tsx"]
	ExcludeDirs  []string `json:"exclude_dirs,omitempty"`  // e.g., ["node_modules", ".git"]
	FocusAreas   []string `json:"focus_areas,omitempty"`   // e.g., ["security", "performance", "architecture"]
}

// ReviewCodebase analyzes the codebase using Ollama
func (h *OllamaHandler) ReviewCodebase(req ReviewCodebaseRequest) (string, error) {
	// This will be implemented by the script that walks the filesystem
	// For now, return a placeholder
	return "", fmt.Errorf("use the review_codebase script for full codebase analysis")
}
