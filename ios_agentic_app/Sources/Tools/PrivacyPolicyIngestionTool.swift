// Privacy Policy Ingestion Tool: Parses privacy policies into ClauseLang structured primitives
import Foundation

/// Tool for ingesting privacy policies and converting them to ClauseLang clauses
public struct PrivacyPolicyIngestionTool: AgentTool {
    public let name = "privacy_policy_ingest"
    public let description = "Ingest privacy policy documents and convert them to structured ClauseLang clauses"
    
    public var inputSchema: [String: String] {
        [
            "policy_text": "The privacy policy text to parse",
            "policy_format": "Format: 'text', 'json', or 'yaml' (default: 'text')",
            "jurisdiction": "Jurisdiction: 'GDPR', 'CCPA', 'PIPEDA', 'LGPD', or custom",
            "extract_clauses": "Whether to extract individual clauses (default: true)"
        ]
    }
    
    private let parser: ClauseLangParser
    private let knowledgeEscort: KnowledgeEscort?
    
    public init(parser: ClauseLangParser, knowledgeEscort: KnowledgeEscort? = nil) {
        self.parser = parser
        self.knowledgeEscort = knowledgeEscort
    }
    
    public func call(args: [String: String], policy: ToolPolicy) async throws -> String {
        guard let policyText = args["policy_text"] else {
            throw ToolError.missingArgument("policy_text")
        }
        
        let format = args["policy_format"] ?? "text"
        let jurisdictionStr = args["jurisdiction"]
        let extractClauses = args["extract_clauses"]?.lowercased() != "false"
        
        // Parse jurisdiction
        let jurisdiction: Jurisdiction? = jurisdictionStr.flatMap { Jurisdiction(rawValue: $0) }
        
        // Ingest the policy
        let result = try await ingestPolicy(
            text: policyText,
            format: format,
            jurisdiction: jurisdiction,
            extractClauses: extractClauses
        )
        
        // Store in knowledge base if available
        if let escort = knowledgeEscort {
            await storeInKnowledgeBase(result, escort: escort)
        }
        
        // Return structured result
        return formatIngestionResult(result)
    }
    
    // MARK: - Policy Ingestion
    
    private func ingestPolicy(
        text: String,
        format: String,
        jurisdiction: Jurisdiction?,
        extractClauses: Bool
    ) async throws -> PolicyIngestionResult {
        switch format.lowercased() {
        case "json":
            return try await ingestFromJSON(text: text, jurisdiction: jurisdiction)
        case "yaml":
            return try await ingestFromYAML(text: text, jurisdiction: jurisdiction)
        default:
            return try await ingestFromText(text: text, jurisdiction: jurisdiction, extractClauses: extractClauses)
        }
    }
    
    /// Ingest from natural language text
    private func ingestFromText(
        text: String,
        jurisdiction: Jurisdiction?,
        extractClauses: Bool
    ) async throws -> PolicyIngestionResult {
        // Step 1: Parse text into semantic clauses
        let extractedClauses = try await extractClausesFromText(text)
        
        // Step 2: Map to ClauseLang syntax
        let clauseLangClauses = try await mapToClauseLang(extractedClauses)
        
        // Step 3: Create contract primitives
        let contract = ContractPrimitive(
            id: "privacy-policy-\(UUID().uuidString.prefix(8))",
            title: "Privacy Policy",
            parties: [.dataSubject, .controller],
            clauses: clauseLangClauses,
            jurisdiction: jurisdiction,
            metadata: ContractMetadata(
                version: "1.0.0",
                effectiveDate: Date(),
                source: "ingested_policy"
            )
        )
        
        // Step 4: Create policy document
        let policyDoc = PolicyDocument(
            id: "policy-\(UUID().uuidString.prefix(8))",
            title: "Privacy Policy",
            parties: [.dataSubject, .controller],
            clauses: clauseLangClauses,
            jurisdiction: jurisdiction,
            metadata: contract.metadata
        )
        
        return PolicyIngestionResult(
            contract: contract,
            policyDocument: policyDoc,
            extractedClauses: clauseLangClauses,
            jurisdiction: jurisdiction
        )
    }
    
    /// Extract clauses from natural language text
    private func extractClausesFromText(_ text: String) async throws -> [ExtractedClause] {
        // TODO: Use MLX LLM for semantic extraction
        // For now, use heuristic extraction
        
        var clauses: [ExtractedClause] = []
        
        // Look for common privacy policy patterns
        let patterns: [(String, ClauseType)] = [
            ("consent|explicit consent|opt-in", .consent),
            ("retention|retain|keep.*data|store.*data", .retention),
            ("share|sharing|third.party|transfer", .sharing),
            ("delete|remove|erase|purge", .deletion),
            ("access|view|retrieve|obtain", .access),
            ("notify|notification|inform|alert", .notification),
            ("security|encrypt|protect|secure", .security)
        ]
        
        for (pattern, type) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let clauseText = String(text[range])
                        clauses.append(ExtractedClause(
                            type: type,
                            text: clauseText,
                            conditions: extractConditions(from: clauseText),
                            actions: extractActions(from: clauseText)
                        ))
                    }
                }
            }
        }
        
        return clauses
    }
    
    private func extractConditions(from text: String) -> [String] {
        // Extract conditions like "when", "if", "after"
        var conditions: [String] = []
        let conditionPatterns = ["when", "if", "after", "before", "within"]
        
        for pattern in conditionPatterns {
            if text.lowercased().contains(pattern) {
                // Extract surrounding context
                if let range = text.lowercased().range(of: pattern) {
                    let start = max(0, text.distance(from: text.startIndex, to: range.lowerBound) - 50)
                    let end = min(text.count, text.distance(from: text.startIndex, to: range.upperBound) + 100)
                    let conditionText = String(text[text.index(text.startIndex, offsetBy: start)..<text.index(text.startIndex, offsetBy: end)])
                    conditions.append(conditionText)
                }
            }
        }
        
        return conditions
    }
    
    private func extractActions(from text: String) -> [String] {
        // Extract actions like "will", "shall", "must"
        var actions: [String] = []
        let actionPatterns = ["will", "shall", "must", "may", "can"]
        
        for pattern in actionPatterns {
            if text.lowercased().contains(pattern) {
                // Extract surrounding context
                if let range = text.lowercased().range(of: pattern) {
                    let start = max(0, text.distance(from: text.startIndex, to: range.lowerBound) - 20)
                    let end = min(text.count, text.distance(from: text.startIndex, to: range.upperBound) + 80)
                    let actionText = String(text[text.index(text.startIndex, offsetBy: start)..<text.index(text.startIndex, offsetBy: end)])
                    actions.append(actionText)
                }
            }
        }
        
        return actions
    }
    
    /// Map extracted clauses to ClauseLang syntax
    private func mapToClauseLang(_ extracted: [ExtractedClause]) async throws -> [Clause] {
        var clauses: [Clause] = []
        
        for extractedClause in extracted {
            // Convert to ClauseLang syntax
            let clauseLangSyntax = try convertToClauseLangSyntax(extractedClause)
            
            // Parse using ClauseLang parser
            let clause = try await parser.parse(clauseLangSyntax)
            clauses.append(clause)
        }
        
        return clauses
    }
    
    private func convertToClauseLangSyntax(_ extracted: ExtractedClause) throws -> String {
        // Convert extracted clause to ClauseLang syntax
        // This is a simplified conversion - can be enhanced with MLX
        
        var conditions: [String] = []
        var actions: [String] = []
        
        // Map conditions
        for conditionText in extracted.conditions {
            // Try to extract variable and value
            if let condition = parseConditionText(conditionText) {
                conditions.append(condition)
            }
        }
        
        // Map actions
        for actionText in extracted.actions {
            if let action = parseActionText(actionText, type: extracted.type) {
                actions.append(action)
            }
        }
        
        // Build ClauseLang syntax
        let whenPart = conditions.isEmpty ? "true" : conditions.joined(separator: " AND ")
        let thenPart = actions.isEmpty ? "allow" : actions.joined(separator: " AND ")
        
        return "WHEN \(whenPart) THEN \(thenPart)"
    }
    
    private func parseConditionText(_ text: String) -> String? {
        // Simple parsing - can be enhanced
        // Look for patterns like "after 90 days", "when consent is explicit", etc.
        if text.lowercased().contains("90") && text.lowercased().contains("day") {
            return "duration > 90 days"
        }
        if text.lowercased().contains("consent") && text.lowercased().contains("explicit") {
            return "consent == 'explicit'"
        }
        return nil
    }
    
    private func parseActionText(_ text: String, type: ClauseType) -> String? {
        // Map to ClauseLang actions based on type
        switch type {
        case .consent:
            return "allow_access"
        case .retention:
            return "delete_data"
        case .sharing:
            return "notify_controller"
        case .deletion:
            return "delete_data"
        case .access:
            return "allow_access"
        case .notification:
            return "notify"
        case .security:
            return "secure_data"
        default:
            return nil
        }
    }
    
    /// Ingest from JSON
    private func ingestFromJSON(text: String, jurisdiction: Jurisdiction?) async throws -> PolicyIngestionResult {
        guard let data = text.data(using: .utf8) else {
            throw ToolError.invalidArgument("policy_text", "Invalid UTF-8 encoding")
        }
        
        let policyDoc = try await parser.parsePolicyDocument(from: data, format: .json)
        
        let contract = ContractPrimitive(
            id: policyDoc.id,
            title: policyDoc.title,
            parties: policyDoc.parties,
            clauses: policyDoc.clauses,
            jurisdiction: policyDoc.jurisdiction,
            metadata: policyDoc.metadata
        )
        
        return PolicyIngestionResult(
            contract: contract,
            policyDocument: policyDoc,
            extractedClauses: policyDoc.clauses,
            jurisdiction: jurisdiction ?? policyDoc.jurisdiction
        )
    }
    
    /// Ingest from YAML
    private func ingestFromYAML(text: String, jurisdiction: Jurisdiction?) async throws -> PolicyIngestionResult {
        // TODO: Implement YAML parsing
        throw ToolError.notImplemented("YAML parsing not yet supported")
    }
    
    /// Store in knowledge base
    private func storeInKnowledgeBase(_ result: PolicyIngestionResult, escort: KnowledgeEscort) async {
        // Create knowledge items from clauses
        for clause in result.extractedClauses {
            let knowledgeItem = KnowledgeItem(
                title: "Privacy Policy Clause: \(clause.id)",
                summary: clause.type.rawValue,
                content: formatClauseForStorage(clause),
                source: .external("privacy_policy_ingestion"),
                entities: [],
                relationships: []
            )
            // TODO: Add to knowledge base
        }
    }
    
    private func formatClauseForStorage(_ clause: Clause) -> String {
        let conditions = clause.conditions.map { "\($0.variable) \($0.operator.rawValue) \($0.value)" }.joined(separator: ", ")
        let actions = clause.actions.map { $0.name }.joined(separator: ", ")
        return "WHEN \(conditions) THEN \(actions)"
    }
    
    private func formatIngestionResult(_ result: PolicyIngestionResult) -> String {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let jsonData = try? jsonEncoder.encode(result.contract),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        // Fallback to simple text
        return """
        Privacy Policy Ingested:
        - Contract ID: \(result.contract.id)
        - Clauses: \(result.extractedClauses.count)
        - Jurisdiction: \(result.jurisdiction?.rawValue ?? "None")
        """
    }
}

// MARK: - Supporting Types

private struct ExtractedClause {
    let type: ClauseType
    let text: String
    let conditions: [String]
    let actions: [String]
}

private struct PolicyIngestionResult {
    let contract: ContractPrimitive
    let policyDocument: PolicyDocument
    let extractedClauses: [Clause]
    let jurisdiction: Jurisdiction?
}

enum ToolError: Error, LocalizedError {
    case missingArgument(String)
    case invalidArgument(String, String)
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .missingArgument(let arg):
            return "Missing required argument: \(arg)"
        case .invalidArgument(let arg, let reason):
            return "Invalid argument \(arg): \(reason)"
        case .notImplemented(let feature):
            return "Not implemented: \(feature)"
        }
    }
}
