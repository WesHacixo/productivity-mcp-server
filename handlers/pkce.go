package handlers

import (
	"crypto/sha256"
	"encoding/base64"
	"fmt"
)

// AuthCodeData stores authorization code with PKCE data
type AuthCodeData struct {
	Code                string
	ClientID            string
	RedirectURI         string
	CodeChallenge       string
	CodeChallengeMethod string
	Scope               string
	State               string
	ExpiresAt           int64
	Used                bool
}

// In-memory storage for auth codes (TODO: Move to database)
var authCodeStore = make(map[string]*AuthCodeData)

// ValidatePKCE validates the code_verifier against the stored code_challenge
// Per OAuth 2.1 RFC 7636, S256 method requires:
// - code_challenge = base64url(sha256(ASCII(code_verifier)))
func ValidatePKCE(codeChallenge, codeChallengeMethod, codeVerifier string) error {
	// #region agent log
	debugLog("pkce.go:28", "ValidatePKCE entry", map[string]interface{}{
		"hasCodeChallenge": codeChallenge != "",
		"method":           codeChallengeMethod,
		"hasCodeVerifier":  codeVerifier != "",
		"hypothesisId":     "H5",
	})
	// #endregion

	if codeChallengeMethod == "" {
		// PKCE is optional per spec, but recommended
		return nil
	}

	if codeChallengeMethod != "S256" && codeChallengeMethod != "plain" {
		return fmt.Errorf("unsupported code_challenge_method: %s (only S256 and plain are supported)", codeChallengeMethod)
	}

	if codeVerifier == "" {
		return fmt.Errorf("code_verifier is required when code_challenge is provided")
	}

	var computedChallenge string

	switch codeChallengeMethod {
	case "S256":
		// Compute SHA256 hash of code_verifier
		hash := sha256.Sum256([]byte(codeVerifier))
		// Base64URL encode
		computedChallenge = base64.RawURLEncoding.EncodeToString(hash[:])
		// #region agent log
		debugLog("pkce.go:50", "PKCE S256 computation", map[string]interface{}{
			"codeVerifier":      codeVerifier,
			"computedChallenge": computedChallenge,
			"storedChallenge":   codeChallenge,
			"match":             computedChallenge == codeChallenge,
			"hypothesisId":      "H5",
		})
		// #endregion
	case "plain":
		// Plain method: code_challenge == code_verifier
		computedChallenge = codeVerifier
		// #region agent log
		debugLog("pkce.go:58", "PKCE plain comparison", map[string]interface{}{
			"computedChallenge": computedChallenge,
			"storedChallenge":   codeChallenge,
			"match":             computedChallenge == codeChallenge,
			"hypothesisId":      "H5",
		})
		// #endregion
	default:
		return fmt.Errorf("unsupported code_challenge_method: %s", codeChallengeMethod)
	}

	// Compare computed challenge with provided challenge
	if computedChallenge != codeChallenge {
		// #region agent log
		debugLog("pkce.go:70", "PKCE validation failed", map[string]interface{}{
			"computedChallenge": computedChallenge,
			"storedChallenge":   codeChallenge,
			"hypothesisId":      "H5",
		})
		// #endregion
		return fmt.Errorf("code_verifier does not match code_challenge")
	}

	// #region agent log
	debugLog("pkce.go:78", "PKCE validation success", map[string]interface{}{
		"hypothesisId": "H5",
	})
	// #endregion
	return nil
}

// StoreAuthCode stores an authorization code with PKCE data
func StoreAuthCode(code string, data *AuthCodeData) {
	authCodeStore[code] = data
}

// GetAuthCode retrieves an authorization code and marks it as used
func GetAuthCode(code string) (*AuthCodeData, error) {
	data, exists := authCodeStore[code]
	if !exists {
		return nil, fmt.Errorf("authorization code not found")
	}

	if data.Used {
		return nil, fmt.Errorf("authorization code has already been used")
	}

	// Mark as used (one-time use)
	data.Used = true

	return data, nil
}

// CleanExpiredAuthCodes removes expired auth codes (should be called periodically)
func CleanExpiredAuthCodes() {
	// TODO: Implement cleanup logic
	// For now, in-memory store will grow, but in production this should be in database with TTL
}
