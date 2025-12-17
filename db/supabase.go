package db

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
)

// SupabaseClient wraps HTTP client for Supabase REST API
type SupabaseClient struct {
	baseURL    string
	apiKey     string
	httpClient *http.Client
}

// NewSupabaseClient creates a new Supabase client
func NewSupabaseClient(supabaseURL, supabaseKey string) (*SupabaseClient, error) {
	// Ensure URL ends with /rest/v1
	baseURL := supabaseURL
	if baseURL[len(baseURL)-1] != '/' {
		baseURL += "/"
	}
	baseURL += "rest/v1/"

	log.Printf("Supabase client initialized for: %s", baseURL)

	return &SupabaseClient{
		baseURL:    baseURL,
		apiKey:     supabaseKey,
		httpClient: &http.Client{},
	}, nil
}

// Close closes the database connection (no-op for HTTP client)
func (sc *SupabaseClient) Close() error {
	return nil
}

// makeRequest makes an HTTP request to Supabase REST API
func (sc *SupabaseClient) makeRequest(method, endpoint string, body interface{}) (*http.Response, error) {
	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request body: %w", err)
		}
		reqBody = bytes.NewBuffer(jsonData)
	}

	req, err := http.NewRequest(method, sc.baseURL+endpoint, reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("apikey", sc.apiKey)
	req.Header.Set("Authorization", "Bearer "+sc.apiKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Prefer", "return=representation")

	resp, err := sc.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}

	return resp, nil
}

// GetTask retrieves a task by ID from Supabase
func (sc *SupabaseClient) GetTask(taskID string) (map[string]interface{}, error) {
	resp, err := sc.makeRequest("GET", fmt.Sprintf("tasks?id=eq.%s&select=*", url.QueryEscape(taskID)), nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to get task: %s - %s", resp.Status, string(body))
	}

	var tasks []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&tasks); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if len(tasks) == 0 {
		return nil, fmt.Errorf("task not found")
	}

	return tasks[0], nil
}

// CreateTask creates a new task in Supabase
func (sc *SupabaseClient) CreateTask(userID string, taskData map[string]interface{}) (string, error) {
	taskData["user_id"] = userID
	resp, err := sc.makeRequest("POST", "tasks", taskData)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("failed to create task: %s - %s", resp.Status, string(body))
	}

	var tasks []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&tasks); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if len(tasks) == 0 {
		return "", fmt.Errorf("no task returned from create")
	}

	id, ok := tasks[0]["id"].(string)
	if !ok {
		return "", fmt.Errorf("invalid task ID in response")
	}

	return id, nil
}

// UpdateTask updates a task in Supabase
func (sc *SupabaseClient) UpdateTask(taskID string, taskData map[string]interface{}) error {
	resp, err := sc.makeRequest("PATCH", fmt.Sprintf("tasks?id=eq.%s", url.QueryEscape(taskID)), taskData)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to update task: %s - %s", resp.Status, string(body))
	}

	return nil
}

// DeleteTask deletes a task from Supabase
func (sc *SupabaseClient) DeleteTask(taskID string) error {
	resp, err := sc.makeRequest("DELETE", fmt.Sprintf("tasks?id=eq.%s", url.QueryEscape(taskID)), nil)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to delete task: %s - %s", resp.Status, string(body))
	}

	return nil
}

// GetUserTasks retrieves all tasks for a user
func (sc *SupabaseClient) GetUserTasks(userID string) ([]map[string]interface{}, error) {
	resp, err := sc.makeRequest("GET", fmt.Sprintf("tasks?user_id=eq.%s&select=*&order=created_at.desc", url.QueryEscape(userID)), nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to get user tasks: %s - %s", resp.Status, string(body))
	}

	var tasks []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&tasks); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return tasks, nil
}

// GetGoal retrieves a goal by ID from Supabase
func (sc *SupabaseClient) GetGoal(goalID string) (map[string]interface{}, error) {
	resp, err := sc.makeRequest("GET", fmt.Sprintf("goals?id=eq.%s&select=*", url.QueryEscape(goalID)), nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to get goal: %s - %s", resp.Status, string(body))
	}

	var goals []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&goals); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if len(goals) == 0 {
		return nil, fmt.Errorf("goal not found")
	}

	return goals[0], nil
}

// CreateGoal creates a new goal in Supabase
func (sc *SupabaseClient) CreateGoal(userID string, goalData map[string]interface{}) (string, error) {
	goalData["user_id"] = userID
	resp, err := sc.makeRequest("POST", "goals", goalData)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("failed to create goal: %s - %s", resp.Status, string(body))
	}

	var goals []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&goals); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if len(goals) == 0 {
		return "", fmt.Errorf("no goal returned from create")
	}

	id, ok := goals[0]["id"].(string)
	if !ok {
		return "", fmt.Errorf("invalid goal ID in response")
	}

	return id, nil
}

// UpdateGoal updates a goal in Supabase
func (sc *SupabaseClient) UpdateGoal(goalID string, goalData map[string]interface{}) error {
	resp, err := sc.makeRequest("PATCH", fmt.Sprintf("goals?id=eq.%s", url.QueryEscape(goalID)), goalData)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to update goal: %s - %s", resp.Status, string(body))
	}

	return nil
}

// DeleteGoal deletes a goal from Supabase
func (sc *SupabaseClient) DeleteGoal(goalID string) error {
	resp, err := sc.makeRequest("DELETE", fmt.Sprintf("goals?id=eq.%s", url.QueryEscape(goalID)), nil)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("failed to delete goal: %s - %s", resp.Status, string(body))
	}

	return nil
}

// GetUserGoals retrieves all goals for a user
func (sc *SupabaseClient) GetUserGoals(userID string) ([]map[string]interface{}, error) {
	resp, err := sc.makeRequest("GET", fmt.Sprintf("goals?user_id=eq.%s&select=*&order=created_at.desc", url.QueryEscape(userID)), nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to get user goals: %s - %s", resp.Status, string(body))
	}

	var goals []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&goals); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return goals, nil
}
