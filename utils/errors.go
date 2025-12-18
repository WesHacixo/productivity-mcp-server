package utils

import (
	"fmt"
	"net/http"
)

// AppError represents an application error with context
type AppError struct {
	Code       string
	Message    string
	HTTPStatus int
	Err        error
	Fields     map[string]interface{}
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Err)
	}
	return e.Message
}

func (e *AppError) Unwrap() error {
	return e.Err
}

// NewAppError creates a new application error
func NewAppError(code, message string, httpStatus int) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		HTTPStatus: httpStatus,
		Fields:     make(map[string]interface{}),
	}
}

// WithError wraps an underlying error
func (e *AppError) WithError(err error) *AppError {
	e.Err = err
	return e
}

// WithField adds a field to the error
func (e *AppError) WithField(key string, value interface{}) *AppError {
	if e.Fields == nil {
		e.Fields = make(map[string]interface{})
	}
	e.Fields[key] = value
	return e
}

// WithFields adds multiple fields to the error
func (e *AppError) WithFields(fields map[string]interface{}) *AppError {
	if e.Fields == nil {
		e.Fields = make(map[string]interface{})
	}
	for k, v := range fields {
		e.Fields[k] = v
	}
	return e
}

// Common error codes
var (
	ErrCodeValidation   = "VALIDATION_ERROR"
	ErrCodeNotFound     = "NOT_FOUND"
	ErrCodeUnauthorized = "UNAUTHORIZED"
	ErrCodeForbidden    = "FORBIDDEN"
	ErrCodeInternal     = "INTERNAL_ERROR"
	ErrCodeExternal     = "EXTERNAL_SERVICE_ERROR"
	ErrCodeRateLimit    = "RATE_LIMIT_EXCEEDED"
	ErrCodeTimeout      = "TIMEOUT"
	ErrCodeBadRequest   = "BAD_REQUEST"
)

// Common error constructors
func ErrValidation(message string) *AppError {
	return NewAppError(ErrCodeValidation, message, http.StatusBadRequest)
}

func ErrNotFound(resource string) *AppError {
	return NewAppError(ErrCodeNotFound, fmt.Sprintf("%s not found", resource), http.StatusNotFound)
}

func ErrUnauthorized(message string) *AppError {
	if message == "" {
		message = "Unauthorized"
	}
	return NewAppError(ErrCodeUnauthorized, message, http.StatusUnauthorized)
}

func ErrForbidden(message string) *AppError {
	if message == "" {
		message = "Forbidden"
	}
	return NewAppError(ErrCodeForbidden, message, http.StatusForbidden)
}

func ErrInternal(message string) *AppError {
	return NewAppError(ErrCodeInternal, message, http.StatusInternalServerError)
}

func ErrExternal(service, message string) *AppError {
	return NewAppError(ErrCodeExternal, fmt.Sprintf("%s: %s", service, message), http.StatusBadGateway)
}

func ErrTimeout(operation string) *AppError {
	return NewAppError(ErrCodeTimeout, fmt.Sprintf("%s timed out", operation), http.StatusGatewayTimeout)
}
