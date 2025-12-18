package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func main() {
	var (
		basePath     = flag.String("path", ".", "Base path to review")
		ollamaURL    = flag.String("ollama-url", "http://100.74.59.83:11434", "Ollama server URL")
		modelName    = flag.String("model", "qwen3-coder:480b-cloud", "Ollama model to use")
		filePatterns = flag.String("patterns", "*.go,*.ts,*.tsx,*.swift,*.js,*.jsx", "Comma-separated file patterns")
		excludeDirs  = flag.String("exclude", "node_modules,.git,vendor,build,dist,.next,ios_agentic_app/.build", "Comma-separated directories to exclude")
		focusAreas   = flag.String("focus", "architecture,security,performance,best-practices", "Comma-separated focus areas")
		outputFile   = flag.String("output", "", "Output file for review (default: stdout)")
		maxFiles     = flag.Int("max-files", 50, "Maximum number of files to review")
		chunkSize    = flag.Int("chunk-size", 10, "Number of files to review per chunk")
	)
	flag.Parse()

	// Parse patterns
	patterns := strings.Split(*filePatterns, ",")
	for i := range patterns {
		patterns[i] = strings.TrimSpace(patterns[i])
	}

	// Parse exclude dirs
	excludeList := strings.Split(*excludeDirs, ",")
	for i := range excludeList {
		excludeList[i] = strings.TrimSpace(excludeList[i])
	}

	// Parse focus areas
	focusList := strings.Split(*focusAreas, ",")
	for i := range focusList {
		focusList[i] = strings.TrimSpace(focusList[i])
	}

	fmt.Printf("🔍 Codebase Review with Ollama\n")
	fmt.Printf("   Path: %s\n", *basePath)
	fmt.Printf("   Ollama: %s\n", *ollamaURL)
	fmt.Printf("   Model: %s\n", *modelName)
	fmt.Printf("   Patterns: %v\n", patterns)
	fmt.Printf("   Exclude: %v\n", excludeList)
	fmt.Printf("   Focus: %v\n", focusList)
	fmt.Printf("   Max files: %d\n", *maxFiles)
	fmt.Printf("   Chunk size: %d\n\n", *chunkSize)

	// Initialize Ollama client
	ollamaClient := NewOllamaClient(*ollamaURL, *modelName)

	// Collect files
	fmt.Println("📁 Collecting files...")
	files, err := collectFiles(*basePath, patterns, excludeList, *maxFiles)
	if err != nil {
		log.Fatalf("Failed to collect files: %v", err)
	}

	fmt.Printf("   Found %d files to review\n\n", len(files))

	// Review in chunks
	var allReviews []string
	for i := 0; i < len(files); i += *chunkSize {
		end := i + *chunkSize
		if end > len(files) {
			end = len(files)
		}
		chunk := files[i:end]

		fmt.Printf("📝 Reviewing chunk %d/%d (%d files)...\n", (i / *chunkSize) + 1, (len(files) + *chunkSize - 1) / *chunkSize, len(chunk))

		review, err := reviewChunk(ollamaClient, chunk, *basePath, focusList)
		if err != nil {
			log.Printf("Error reviewing chunk: %v", err)
			continue
		}

		allReviews = append(allReviews, review)
		fmt.Printf("   ✅ Chunk review complete\n\n")
	}

	// Generate final summary
	fmt.Println("📊 Generating final summary...")
	summary, err := generateSummary(ollamaClient, allReviews, focusList)
	if err != nil {
		log.Printf("Error generating summary: %v", err)
	} else {
		allReviews = append(allReviews, "\n=== FINAL SUMMARY ===\n\n"+summary)
	}

	// Output results
	output := strings.Join(allReviews, "\n\n---\n\n")
	if *outputFile != "" {
		err := os.WriteFile(*outputFile, []byte(output), 0644)
		if err != nil {
			log.Fatalf("Failed to write output: %v", err)
		}
		fmt.Printf("✅ Review saved to: %s\n", *outputFile)
	} else {
		fmt.Println("\n" + strings.Repeat("=", 80))
		fmt.Println(output)
	}
}

func collectFiles(basePath string, patterns []string, excludeDirs []string, maxFiles int) ([]string, error) {
	var files []string

	err := filepath.WalkDir(basePath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Check if directory should be excluded
		if d.IsDir() {
			relPath, _ := filepath.Rel(basePath, path)
			for _, exclude := range excludeDirs {
				if strings.Contains(relPath, exclude) {
					return filepath.SkipDir
				}
			}
			return nil
		}

		// Check if file matches patterns
		for _, pattern := range patterns {
			matched, _ := filepath.Match(pattern, filepath.Base(path))
			if matched {
				files = append(files, path)
				if len(files) >= maxFiles {
					return io.EOF // Signal to stop walking
				}
				break
			}
		}

		return nil
	})

	if err != nil && err != io.EOF {
		return nil, err
	}

	return files, nil
}

// OllamaClient handles Ollama API calls
type OllamaClient struct {
	url        string
	model      string
	httpClient *http.Client
}

func NewOllamaClient(url, model string) *OllamaClient {
	return &OllamaClient{
		url:        url,
		model:      model,
		httpClient: &http.Client{Timeout: 120 * time.Second},
	}
}

func (c *OllamaClient) Generate(prompt, systemPrompt string) (string, error) {
	req := map[string]interface{}{
		"model":  c.model,
		"prompt": prompt,
		"stream": false,
	}
	if systemPrompt != "" {
		req["system"] = systemPrompt
	}

	jsonData, err := json.Marshal(req)
	if err != nil {
		return "", err
	}

	resp, err := c.httpClient.Post(c.url+"/api/generate", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("server returned status %d: %s", resp.StatusCode, string(body))
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}

	if response, ok := result["response"].(string); ok {
		return response, nil
	}

	return "", fmt.Errorf("no response in result")
}

func reviewChunk(client *OllamaClient, files []string, basePath string, focusAreas []string) (string, error) {
	// Read file contents
	var fileContents []string
	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			log.Printf("Warning: Could not read %s: %v", file, err)
			continue
		}

		relPath, _ := filepath.Rel(basePath, file)
		fileContents = append(fileContents, fmt.Sprintf("=== %s ===\n%s", relPath, string(content)))
	}

	// Build prompt
	focusStr := strings.Join(focusAreas, ", ")
	prompt := fmt.Sprintf(`You are an expert code reviewer. Review the following code files focusing on: %s.

Provide a comprehensive review covering:
1. Code quality and best practices
2. Potential bugs or issues
3. Security concerns
4. Performance optimizations
5. Architecture and design patterns
6. Suggestions for improvement

Code files:
%s

Provide a detailed review for each file, then an overall assessment.`, focusStr, strings.Join(fileContents, "\n\n"))

	systemPrompt := "You are an expert software engineer and code reviewer with deep knowledge of Go, TypeScript, React, Swift, and modern software architecture. Provide thorough, actionable feedback."

	// Call Ollama
	review, err := client.Generate(prompt, systemPrompt)
	if err != nil {
		return "", fmt.Errorf("failed to generate review: %w", err)
	}

	return review, nil
}

func generateSummary(client *OllamaClient, reviews []string, focusAreas []string) (string, error) {
	focusStr := strings.Join(focusAreas, ", ")
	prompt := fmt.Sprintf(`Based on the following code reviews, provide a comprehensive summary covering:

1. Overall codebase health
2. Key strengths
3. Critical issues that need attention
4. Priority recommendations
5. Architecture assessment

Focus areas: %s

Reviews:
%s

Provide a concise but comprehensive executive summary.`, focusStr, strings.Join(reviews, "\n\n---\n\n"))

	systemPrompt := "You are a senior software architect providing an executive summary of codebase reviews."

	summary, err := client.Generate(prompt, systemPrompt)
	if err != nil {
		return "", fmt.Errorf("failed to generate summary: %w", err)
	}

	return summary, nil
}
