package utils

import (
	"encoding/json"
	"log"
	"os"
	"time"
)

// LogLevel represents logging levels
type LogLevel string

const (
	LogLevelDebug LogLevel = "DEBUG"
	LogLevelInfo  LogLevel = "INFO"
	LogLevelWarn  LogLevel = "WARN"
	LogLevelError LogLevel = "ERROR"
)

// Logger provides structured logging
type Logger struct {
	level LogLevel
}

// NewLogger creates a new logger instance
func NewLogger() *Logger {
	level := LogLevel(os.Getenv("LOG_LEVEL"))
	if level == "" {
		level = LogLevelInfo
	}
	return &Logger{level: level}
}

// LogEntry represents a structured log entry
type LogEntry struct {
	Timestamp string                 `json:"timestamp"`
	Level     string                 `json:"level"`
	Message   string                 `json:"message"`
	Fields    map[string]interface{} `json:"fields,omitempty"`
	Error     string                 `json:"error,omitempty"`
}

func (l *Logger) shouldLog(level LogLevel) bool {
	levels := map[LogLevel]int{
		LogLevelDebug: 0,
		LogLevelInfo:  1,
		LogLevelWarn:  2,
		LogLevelError: 3,
	}
	return levels[level] >= levels[l.level]
}

func (l *Logger) log(level LogLevel, message string, fields map[string]interface{}, err error) {
	if !l.shouldLog(level) {
		return
	}

	entry := LogEntry{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Level:     string(level),
		Message:   message,
		Fields:    fields,
	}

	if err != nil {
		entry.Error = err.Error()
	}

	jsonData, _ := json.Marshal(entry)
	log.Println(string(jsonData))
}

// Debug logs a debug message
func (l *Logger) Debug(message string, fields ...map[string]interface{}) {
	var mergedFields map[string]interface{}
	if len(fields) > 0 {
		mergedFields = fields[0]
	}
	l.log(LogLevelDebug, message, mergedFields, nil)
}

// Info logs an info message
func (l *Logger) Info(message string, fields ...map[string]interface{}) {
	var mergedFields map[string]interface{}
	if len(fields) > 0 {
		mergedFields = fields[0]
	}
	l.log(LogLevelInfo, message, mergedFields, nil)
}

// Warn logs a warning message
func (l *Logger) Warn(message string, fields ...map[string]interface{}) {
	var mergedFields map[string]interface{}
	if len(fields) > 0 {
		mergedFields = fields[0]
	}
	l.log(LogLevelWarn, message, mergedFields, nil)
}

// Error logs an error message
func (l *Logger) Error(message string, err error, fields ...map[string]interface{}) {
	var mergedFields map[string]interface{}
	if len(fields) > 0 {
		mergedFields = fields[0]
	}
	l.log(LogLevelError, message, mergedFields, err)
}

// WithFields creates a logger with predefined fields
func (l *Logger) WithFields(fields map[string]interface{}) *FieldLogger {
	return &FieldLogger{
		logger: l,
		fields: fields,
	}
}

// FieldLogger is a logger with predefined fields
type FieldLogger struct {
	logger *Logger
	fields map[string]interface{}
}

func (fl *FieldLogger) mergeFields(additional map[string]interface{}) map[string]interface{} {
	merged := make(map[string]interface{})
	for k, v := range fl.fields {
		merged[k] = v
	}
	for k, v := range additional {
		merged[k] = v
	}
	return merged
}

func (fl *FieldLogger) Debug(message string, fields ...map[string]interface{}) {
	var merged map[string]interface{}
	if len(fields) > 0 {
		merged = fl.mergeFields(fields[0])
	} else {
		merged = fl.fields
	}
	fl.logger.log(LogLevelDebug, message, merged, nil)
}

func (fl *FieldLogger) Info(message string, fields ...map[string]interface{}) {
	var merged map[string]interface{}
	if len(fields) > 0 {
		merged = fl.mergeFields(fields[0])
	} else {
		merged = fl.fields
	}
	fl.logger.log(LogLevelInfo, message, merged, nil)
}

func (fl *FieldLogger) Warn(message string, fields ...map[string]interface{}) {
	var merged map[string]interface{}
	if len(fields) > 0 {
		merged = fl.mergeFields(fields[0])
	} else {
		merged = fl.fields
	}
	fl.logger.log(LogLevelWarn, message, merged, nil)
}

func (fl *FieldLogger) Error(message string, err error, fields ...map[string]interface{}) {
	var merged map[string]interface{}
	if len(fields) > 0 {
		merged = fl.mergeFields(fields[0])
	} else {
		merged = fl.fields
	}
	fl.logger.log(LogLevelError, message, merged, err)
}
