package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

type OllamaTagsResponse struct {
	Models []struct {
		Name       string    `json:"name"`
		ModifiedAt time.Time `json:"modified_at"`
		Size       int64     `json:"size"`
	} `json:"models"`
}

type OllamaGenerateRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
	Stream bool   `json:"stream"`
}

type OllamaGenerateResponse struct {
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

func main() {
	// Get Ollama URL from environment or try multiple IPs
	ollamaURL := os.Getenv("OLLAMA_URL")
	modelName := os.Getenv("OLLAMA_MODEL")
	if modelName == "" {
		modelName = "coder"
	}

	// If no URL specified, try common Mac Studio IPs
	candidateURLs := []string{}
	if ollamaURL != "" {
		candidateURLs = []string{ollamaURL}
	} else {
		// Try common Mac Studio IPs based on network configuration
		candidateURLs = []string{
			"http://192.168.12.160:11434", // WiFi network
			"http://10.10.10.10:11434",    // Thunderbolt bridge
			"http://10.10.20.10:11434",    // eth2Studio network
			"http://localhost:11434",      // Local fallback
		}
	}

	fmt.Printf("🔍 Validating Ollama connection...\n")
	fmt.Printf("   Model: %s\n\n", modelName)

	// Test 1: Find reachable server
	fmt.Println("1️⃣ Testing server connectivity...")
	var workingURL string
	for _, url := range candidateURLs {
		fmt.Printf("   Trying %s...\n", url)
		if err := testServerConnection(url); err == nil {
			workingURL = url
			fmt.Printf("   ✅ Server is reachable at %s\n", url)
			break
		} else {
			fmt.Printf("   ⚠️  %s: %v\n", url, err)
		}
	}

	if workingURL == "" {
		fmt.Printf("\n   ❌ Could not connect to Ollama on any candidate URL\n")
		fmt.Printf("   💡 Try setting OLLAMA_URL environment variable\n")
		fmt.Printf("   💡 Or ensure Ollama is running and accessible\n")
		os.Exit(1)
	}

	ollamaURL = workingURL

	// Test 2: List available models
	fmt.Println("\n2️⃣ Listing available models...")
	models, err := listModels(ollamaURL)
	if err != nil {
		fmt.Printf("   ❌ Failed: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("   ✅ Found %d model(s):\n", len(models))
	for _, model := range models {
		fmt.Printf("      - %s\n", model)
	}

	// Test 3: Check if target model exists
	fmt.Printf("\n3️⃣ Checking if '%s' model is available...\n", modelName)
	modelFound := false
	var matchingModels []string
	for _, model := range models {
		if model == modelName {
			modelFound = true
			matchingModels = append(matchingModels, model)
		} else if len(modelName) > 0 && len(model) >= len(modelName) && model[:len(modelName)] == modelName {
			// Check for partial matches (e.g., "coder" matches "coder:latest")
			matchingModels = append(matchingModels, model)
		}
	}
	if !modelFound {
		fmt.Printf("   ❌ Model '%s' not found in available models\n", modelName)
		if len(matchingModels) > 0 {
			fmt.Printf("   💡 Found similar models: %v\n", matchingModels)
			fmt.Printf("   💡 You might want to use one of these instead\n")
		}
		fmt.Printf("   Available models: %v\n", models)
		
		// Suggest common coder models
		fmt.Printf("\n   💡 Popular coding models you can install:\n")
		fmt.Printf("      - qwen3-coder:480b-cloud (cloud model - should be on Mac Studio)\n")
		fmt.Printf("      - qwen3-coder:30b (local version)\n")
		fmt.Printf("      - deepseek-coder (recommended for coding)\n")
		fmt.Printf("      - stable-code\n")
		fmt.Printf("      - codellama\n")
		fmt.Printf("\n   📝 Note: Mac Studio should already have qwen3-coder:480b-cloud installed\n")
		
		fmt.Printf("\n   📥 To install a coder model, run:\n")
		fmt.Printf("      ollama pull deepseek-coder\n")
		fmt.Printf("   Or for cloud models:\n")
		fmt.Printf("      ollama run qwen3-coder:480b-cloud\n")
		fmt.Printf("   Or if running remotely (see Anetmacsetup project):\n")
		fmt.Printf("      ssh macstudio 'ollama pull deepseek-coder'\n")
		os.Exit(1)
	}
	fmt.Printf("   ✅ Model '%s' is available\n", modelName)

	// Test 4: Test model generation
	fmt.Printf("\n4️⃣ Testing model generation with '%s'...\n", modelName)
	if err := testModelGeneration(ollamaURL, modelName); err != nil {
		fmt.Printf("   ❌ Failed: %v\n", err)
		os.Exit(1)
	}
	fmt.Println("   ✅ Model generation successful")

	fmt.Println("\n✅ All validation tests passed!")
	fmt.Printf("   Ollama server at %s is ready to use with model '%s'\n", ollamaURL, modelName)
}

func testServerConnection(url string) error {
	client := &http.Client{
		Timeout: 3 * time.Second,
	}

	// Try to list models as a connectivity test
	resp, err := client.Get(url + "/api/tags")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("server returned status %d", resp.StatusCode)
	}

	return nil
}

func listModels(url string) ([]string, error) {
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Get(url + "/api/tags")
	if err != nil {
		return nil, fmt.Errorf("failed to list models: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("server returned status %d: %s", resp.StatusCode, string(body))
	}

	var tagsResp OllamaTagsResponse
	if err := json.NewDecoder(resp.Body).Decode(&tagsResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	models := make([]string, 0, len(tagsResp.Models))
	for _, model := range tagsResp.Models {
		models = append(models, model.Name)
	}

	return models, nil
}

func testModelGeneration(url, modelName string) error {
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	reqBody := OllamaGenerateRequest{
		Model:  modelName,
		Prompt: "Say 'Hello, Ollama!' in one sentence.",
		Stream: false,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return fmt.Errorf("failed to marshal request: %w", err)
	}

	resp, err := client.Post(url+"/api/generate", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("server returned status %d: %s", resp.StatusCode, string(body))
	}

	var genResp OllamaGenerateResponse
	if err := json.NewDecoder(resp.Body).Decode(&genResp); err != nil {
		return fmt.Errorf("failed to decode response: %w", err)
	}

	if !genResp.Done {
		return fmt.Errorf("generation did not complete")
	}

	fmt.Printf("      Response: %s\n", genResp.Response)
	if genResp.TotalDuration > 0 {
		fmt.Printf("      Duration: %dms\n", genResp.TotalDuration/1000000)
	}

	return nil
}
