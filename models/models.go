package models

import "time"

// Task represents a productivity task
type Task struct {
	ID                 string     `json:"id"`
	UserID             string     `json:"user_id"`
	Title              string     `json:"title"`
	Description        string     `json:"description"`
	Priority           int        `json:"priority"`
	DueDate            time.Time  `json:"due_date"`
	EstimatedDuration  int        `json:"estimated_duration"`
	Category           string     `json:"category"`
	Completed          bool       `json:"completed"`
	CompletedAt        *time.Time `json:"completed_at"`
	RecurringFrequency string     `json:"recurring_frequency"`
	RecurringInterval  int        `json:"recurring_interval"`
	RecurringEndDate   *time.Time `json:"recurring_end_date"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

// CreateTaskRequest represents a request to create a task
type CreateTaskRequest struct {
	Title              string     `json:"title" binding:"required"`
	Description        string     `json:"description"`
	Priority           int        `json:"priority"`
	DueDate            time.Time  `json:"due_date" binding:"required"`
	EstimatedDuration  int        `json:"estimated_duration"`
	Category           string     `json:"category"`
	RecurringFrequency string     `json:"recurring_frequency"`
	RecurringInterval  int        `json:"recurring_interval"`
	RecurringEndDate   *time.Time `json:"recurring_end_date"`
}

// UpdateTaskRequest represents a request to update a task
type UpdateTaskRequest struct {
	Title              *string    `json:"title"`
	Description        *string    `json:"description"`
	Priority           *int       `json:"priority"`
	DueDate            *time.Time `json:"due_date"`
	EstimatedDuration  *int       `json:"estimated_duration"`
	Category           *string    `json:"category"`
	Completed          *bool      `json:"completed"`
	RecurringFrequency *string    `json:"recurring_frequency"`
	RecurringInterval  *int       `json:"recurring_interval"`
	RecurringEndDate   *time.Time `json:"recurring_end_date"`
}

// Goal represents a long-term productivity goal
type Goal struct {
	ID          string    `json:"id"`
	UserID      string    `json:"user_id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	StartDate   time.Time `json:"start_date"`
	TargetDate  time.Time `json:"target_date"`
	Progress    int       `json:"progress"`
	Archived    bool      `json:"archived"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// CreateGoalRequest represents a request to create a goal
type CreateGoalRequest struct {
	Title       string    `json:"title" binding:"required"`
	Description string    `json:"description"`
	StartDate   time.Time `json:"start_date" binding:"required"`
	TargetDate  time.Time `json:"target_date" binding:"required"`
	Progress    int       `json:"progress"`
}

// UpdateGoalRequest represents a request to update a goal
type UpdateGoalRequest struct {
	Title       *string    `json:"title"`
	Description *string    `json:"description"`
	StartDate   *time.Time `json:"start_date"`
	TargetDate  *time.Time `json:"target_date"`
	Progress    *int       `json:"progress"`
	Archived    *bool      `json:"archived"`
}

// ParseTaskRequest represents a request to parse natural language into a task
type ParseTaskRequest struct {
	Input  string `json:"input" binding:"required"`
	UserID string `json:"user_id" binding:"required"`
}

// ParseTaskResponse represents the response from parsing natural language
type ParseTaskResponse struct {
	Task        *Task    `json:"task"`
	Subtasks    []string `json:"subtasks"`
	Confidence  float64  `json:"confidence"`
	Explanation string   `json:"explanation"`
}

// GenerateSubtasksRequest represents a request to generate subtasks
type GenerateSubtasksRequest struct {
	TaskTitle       string `json:"task_title" binding:"required"`
	TaskDescription string `json:"task_description"`
	UserID          string `json:"user_id" binding:"required"`
}

// GenerateSubtasksResponse represents the response from generating subtasks
type GenerateSubtasksResponse struct {
	Subtasks    []string `json:"subtasks"`
	Explanation string   `json:"explanation"`
}

// ParseFileRequest represents a request to parse a file
type ParseFileRequest struct {
	FileName    string `json:"file_name" binding:"required"`
	FileContent string `json:"file_content" binding:"required"`
	FileType    string `json:"file_type" binding:"required"`
	UserID      string `json:"user_id" binding:"required"`
}

// ParseFileResponse represents the response from parsing a file
type ParseFileResponse struct {
	Tasks         []Task                 `json:"tasks"`
	ExtractedData map[string]interface{} `json:"extracted_data"`
	Summary       string                 `json:"summary"`
}

// AnalyzeProductivityRequest represents a request to analyze productivity
type AnalyzeProductivityRequest struct {
	UserID string `json:"user_id" binding:"required"`
	Days   int    `json:"days"`
}

// AnalyzeProductivityResponse represents the response from analyzing productivity
type AnalyzeProductivityResponse struct {
	CompletedTasks  int      `json:"completed_tasks"`
	TotalTasks      int      `json:"total_tasks"`
	CompletionRate  float64  `json:"completion_rate"`
	Insights        []string `json:"insights"`
	Recommendations []string `json:"recommendations"`
}

// MCPRequest represents a generic MCP request
type MCPRequest struct {
	Jsonrpc string                 `json:"jsonrpc"`
	ID      int                    `json:"id"`
	Method  string                 `json:"method"`
	Params  map[string]interface{} `json:"params"`
}

// MCPResponse represents a generic MCP response
type MCPResponse struct {
	Jsonrpc string      `json:"jsonrpc"`
	ID      int         `json:"id"`
	Result  interface{} `json:"result,omitempty"`
	Error   *MCPError   `json:"error,omitempty"`
}

// MCPError represents an MCP error
type MCPError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}
