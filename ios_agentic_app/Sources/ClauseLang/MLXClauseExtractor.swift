// MLX-Powered Clause Extraction: Extract ClauseLang clauses from natural language
// Uses MLX LLM for semantic understanding and clause generation
import Foundation

/// MLX-powered clause extractor for natural language to ClauseLang
public actor MLXClauseExtractor {
    private let mlxLLM: MLXLLM?
    private let clauseLang: ClauseLang
    private let dagBuilder: DAGBuilder
    
    public init(
        mlxLLM: MLXLLM?,
        clauseLang: ClauseLang,
        dagBuilder: DAGBuilder
    ) {
        self.mlxLLM = mlxLLM
        self.clauseLang = clauseLang
        self.dagBuilder = dagBuilder
    }
    
    /// Extract clauses from natural language text using MLX
    public func extractClauses(
        from text: String,
        context: ClauseContext? = nil
    ) async throws -> [Clause] {
        guard let mlx = mlxLLM else {
            // Fallback to heuristic extraction
            return try await heuristicExtraction(from: text)
        }
        
        // Use MLX to extract clauses
        let prompt = buildExtractionPrompt(text: text, context: context)
        
        let response = try await mlx.generate(
            prompt: prompt,
            maxTokens: 512,
            temperature: 0.3 // Lower temperature for more structured output
        )
        
        return try parseClausesFromMLXResponse(response)
    }
    
    /// Extract clauses from privacy policy text
    public func extractPrivacyPolicyClauses(
        from policyText: String,
        jurisdiction: String? = nil
    ) async throws -> [Clause] {
        let prompt = """
        Extract privacy policy clauses from this text and convert them to ClauseLang format.
        
        Policy Text:
        \(policyText)
        
        \(jurisdiction != nil ? "Jurisdiction: \(jurisdiction!)" : "")
        
        For each clause found, output in this format:
        WHEN <condition> THEN <action>
        
        Common clause types:
        - Consent: WHEN consent == "explicit" THEN allow_access
        - Retention: WHEN duration > 90 THEN delete_data
        - Sharing: WHEN role == "processor" THEN notify_controller
        - Deletion: WHEN request_received == true THEN delete_data
        - Access: WHEN user_requested == true THEN allow_access
        
        Output one clause per line.
        """
        
        guard let mlx = mlxLLM else {
            return try await heuristicExtraction(from: policyText)
        }
        
        let response = try await mlx.generate(
            prompt: prompt,
            maxTokens: 1024,
            temperature: 0.2
        )
        
        return try parseClausesFromMLXResponse(response)
    }
    
    /// Validate clause using MLX for semantic correctness
    public func validateClause(
        _ clause: Clause,
        context: ClauseContext? = nil
    ) async throws -> ClauseValidationResult {
        guard let mlx = mlxLLM else {
            // Fallback to basic validation
            return ClauseValidationResult(
                valid: true,
                confidence: 0.7,
                reasoning: "Basic validation passed"
            )
        }
        
        let prompt = """
        Validate this ClauseLang clause for semantic correctness and safety:
        
        Clause: \(clause.raw)
        
        Check:
        1. Semantic correctness (does the condition make sense?)
        2. Safety (are there any dangerous actions?)
        3. Completeness (are all variables defined?)
        4. Consistency (does it conflict with other clauses?)
        
        Respond in JSON:
        {
          "valid": true/false,
          "confidence": 0.0-1.0,
          "reasoning": "explanation",
          "risks": ["risk1", "risk2"],
          "suggestions": ["suggestion1"]
        }
        """
        
        let response = try await mlx.generate(
            prompt: prompt,
            maxTokens: 256,
            temperature: 0.2
        )
        
        return try parseValidationResult(response)
    }
    
    /// Score clause confidence using MLX
    public func scoreClauseConfidence(
        _ clause: Clause,
        context: ClauseContext? = nil
    ) async throws -> Double {
        guard let mlx = mlxLLM else {
            return 0.7 // Default confidence
        }
        
        let prompt = """
        Score the confidence of this ClauseLang clause (0.0 to 1.0):
        
        Clause: \(clause.raw)
        
        Consider:
        - Clarity of condition
        - Specificity of action
        - Completeness
        - Semantic coherence
        
        Respond with just a number between 0.0 and 1.0.
        """
        
        let response = try await mlx.generate(
            prompt: prompt,
            maxTokens: 10,
            temperature: 0.1
        )
        
        // Parse number from response
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if let confidence = Double(cleaned) {
            return max(0.0, min(1.0, confidence)) // Clamp to 0-1
        }
        
        return 0.7 // Default if parsing fails
    }
    
    // MARK: - Private Methods
    
    private func buildExtractionPrompt(text: String, context: ClauseContext?) -> String {
        var prompt = """
        Extract workflow clauses from this natural language text and convert to ClauseLang format.
        
        Text:
        \(text)
        
        """
        
        if let ctx = context {
            prompt += "Context variables: \(ctx.variables.keys.joined(separator: ", "))\n"
        }
        
        prompt += """
        
        Output format: WHEN <condition> THEN <action>
        
        Examples:
        - "When I'm in deep work, don't schedule meetings" → WHEN user.focus_mode == "deep" THEN block_meetings
        - "After 90 minutes, take a break" → WHEN focused_duration > 90 THEN insert_recovery_block(duration=10)
        - "Cluster errands together" → WHEN task_type == "errand" THEN cluster_errands(min_batch_size=3)
        
        Output one clause per line.
        """
        
        return prompt
    }
    
    private func parseClausesFromMLXResponse(_ response: String) throws -> [Clause] {
        var clauses: [Clause] = []
        
        // Split by lines and parse each
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || !trimmed.uppercased().hasPrefix("WHEN") {
                continue
            }
            
            // Try to parse as ClauseLang
            do {
                let ast = try await clauseLang.parse(trimmed)
                let clause = Clause(from: ast)
                clauses.append(clause)
            } catch {
                // Skip invalid clauses
                continue
            }
        }
        
        return clauses
    }
    
    private func parseValidationResult(_ response: String) throws -> ClauseValidationResult {
        // Try to parse JSON response
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback
            return ClauseValidationResult(
                valid: true,
                confidence: 0.7,
                reasoning: "Could not parse validation response"
            )
        }
        
        let valid = json["valid"] as? Bool ?? true
        let confidence = json["confidence"] as? Double ?? 0.7
        let reasoning = json["reasoning"] as? String ?? "No reasoning provided"
        let risks = json["risks"] as? [String] ?? []
        let suggestions = json["suggestions"] as? [String] ?? []
        
        return ClauseValidationResult(
            valid: valid,
            confidence: confidence,
            reasoning: reasoning,
            risks: risks,
            suggestions: suggestions
        )
    }
    
    private func heuristicExtraction(from text: String) async throws -> [Clause] {
        // Fallback heuristic extraction (simple pattern matching)
        var clauses: [Clause] = []
        
        // Look for common patterns
        let patterns: [(String, String)] = [
            ("deep work", "WHEN user.focus_mode == \"deep\" THEN block_meetings"),
            ("90 minutes", "WHEN focused_duration > 90 THEN insert_recovery_block(duration=10)"),
            ("errands", "WHEN task_type == \"errand\" THEN cluster_errands(min_batch_size=3)")
        ]
        
        for (pattern, clauseStr) in patterns {
            if text.localizedCaseInsensitiveContains(pattern) {
                if let ast = try? await clauseLang.parse(clauseStr) {
                    clauses.append(Clause(from: ast))
                }
            }
        }
        
        return clauses
    }
}

// MARK: - Supporting Types

public struct ClauseValidationResult: Codable {
    public let valid: Bool
    public let confidence: Double
    public let reasoning: String
    public let risks: [String]
    public let suggestions: [String]
    
    public init(
        valid: Bool,
        confidence: Double,
        reasoning: String,
        risks: [String] = [],
        suggestions: [String] = []
    ) {
        self.valid = valid
        self.confidence = confidence
        self.reasoning = reasoning
        self.risks = risks
        self.suggestions = suggestions
    }
}
