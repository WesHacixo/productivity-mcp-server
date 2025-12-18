// Governance: Consent flows, audit trails, policy transparency
// Ethics-as-product-feature with legible governance
import Foundation

/// Governance System - Manages consent, audit trails, and policy transparency
public actor GovernanceSystem {
    private var consentState: ConsentState
    private var auditTrail: [AuditEntry] = []
    private var policyVersions: [PolicyVersion] = []
    
    public init(consentState: ConsentState = ConsentState()) {
        self.consentState = consentState
    }
    
    /// Check consent for an action
    public func checkConsent(for action: String) -> Bool {
        switch action {
        case "learn_patterns", "extract_entities", "build_knowledge_graph":
            return consentState.learningEnabled
        case "store_embeddings", "vector_search":
            return consentState.dataStorageEnabled
        case "share_data", "sync_cloud":
            return consentState.dataSharingEnabled
        default:
            return true // Default allow
        }
    }
    
    /// Revoke consent
    public func revokeConsent(for action: String) async {
        switch action {
        case "learning":
            consentState.learningEnabled = false
            await logAudit("consent_revoked", data: ["action": "learning"])
        case "data_storage":
            consentState.dataStorageEnabled = false
            await logAudit("consent_revoked", data: ["action": "data_storage"])
        case "data_sharing":
            consentState.dataSharingEnabled = false
            await logAudit("consent_revoked", data: ["action": "data_sharing"])
        default:
            break
        }
    }
    
    /// Grant consent
    public func grantConsent(for action: String) async {
        switch action {
        case "learning":
            consentState.learningEnabled = true
            await logAudit("consent_granted", data: ["action": "learning"])
        case "data_storage":
            consentState.dataStorageEnabled = true
            await logAudit("consent_granted", data: ["action": "data_storage"])
        case "data_sharing":
            consentState.dataSharingEnabled = true
            await logAudit("consent_granted", data: ["action": "data_sharing"])
        default:
            break
        }
    }
    
    /// Log audit entry
    public func logAudit(
        _ action: String,
        actor: String = "system",
        data: [String: String]? = nil
    ) async {
        let entry = AuditEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            action: action,
            actor: actor,
            data: data
        )
        auditTrail.append(entry)
        
        // Prune old entries (keep last 1000)
        if auditTrail.count > 1000 {
            auditTrail.removeFirst()
        }
    }
    
    /// Get audit trail
    public func getAuditTrail(limit: Int = 100) -> [AuditEntry] {
        return Array(auditTrail.suffix(limit))
    }
    
    /// Register policy version
    public func registerPolicyVersion(
        _ version: PolicyVersion
    ) async {
        policyVersions.append(version)
        await logAudit("policy_version_registered", data: ["version": version.version])
    }
    
    /// Get current policy version
    public func getCurrentPolicyVersion() -> PolicyVersion? {
        return policyVersions.last
    }
    
    /// Get policy history
    public func getPolicyHistory() -> [PolicyVersion] {
        return policyVersions
    }
    
    /// Handle consent revocation event (from ClauseLang)
    public func handleConsentRevoked() async {
        consentState.learningEnabled = false
        consentState.dataStorageEnabled = false
        consentState.dataSharingEnabled = false
        
        await logAudit("consent_revoked", data: ["scope": "all"])
        
        // Trigger data deletion if requested
        // In real implementation, would trigger actual deletion workflows
    }
    
    /// Delete user data (embeddings, knowledge graph, etc.)
    public func deleteUserData() async {
        await logAudit("data_deletion_requested", data: ["scope": "all"])
        
        // In real implementation, would:
        // 1. Delete embeddings from vector memory
        // 2. Clear knowledge graph
        // 3. Remove stored policies
        // 4. Clear audit trail (or anonymize)
        
        await logAudit("data_deleted", data: ["scope": "all"])
    }
}

// MARK: - Supporting Types

public struct ConsentState: Codable {
    public var learningEnabled: Bool
    public var dataStorageEnabled: Bool
    public var dataSharingEnabled: Bool
    
    public init(
        learningEnabled: Bool = true,
        dataStorageEnabled: Bool = true,
        dataSharingEnabled: Bool = false
    ) {
        self.learningEnabled = learningEnabled
        self.dataStorageEnabled = dataStorageEnabled
        self.dataSharingEnabled = dataSharingEnabled
    }
}

public struct AuditEntry: Codable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let action: String
    public let actor: String
    public let data: [String: String]?
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        action: String,
        actor: String,
        data: [String: String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.actor = actor
        self.data = data
    }
}

public struct PolicyVersion: Codable, Identifiable {
    public let id: String
    public let version: String
    public let effectiveDate: Date
    public let clauses: [Clause]
    public let description: String
    public let changes: [String] // What changed from previous version
    
    public init(
        id: String = UUID().uuidString,
        version: String,
        effectiveDate: Date = Date(),
        clauses: [Clause],
        description: String,
        changes: [String] = []
    ) {
        self.id = id
        self.version = version
        self.effectiveDate = effectiveDate
        self.clauses = clauses
        self.description = description
        self.changes = changes
    }
}

/// Policy Transparency UI - Shows "why this suggestion" with clauses used
public struct PolicyTransparency {
    
    /// Generate "why this suggestion" explanation
    public static func explainSuggestion(
        ko: KernelObject,
        executedNodes: [String],
        inputs: [String: AnyCodable]
    ) -> SuggestionExplanation {
        var explanation = "This suggestion was generated using the following rules:\n\n"
        
        // List executed clauses
        for nodeId in executedNodes {
            if let node = ko.dagNodes.first(where: { $0.id == nodeId }) {
                let ricardian = RicardianRenderer.render(node.clause)
                explanation += "**\(node.clause.description ?? node.id):**\n"
                explanation += "\(ricardian.prose)\n\n"
            }
        }
        
        // Show inputs used
        if !inputs.isEmpty {
            explanation += "**Inputs used:**\n"
            for (key, value) in inputs {
                explanation += "- \(key): \(formatValue(value))\n"
            }
            explanation += "\n"
        }
        
        // Show what wasn't used (if applicable)
        let allInputs = Set(ko.inputs)
        let usedInputs = Set(inputs.keys)
        let unusedInputs = allInputs.subtracting(usedInputs)
        
        if !unusedInputs.isEmpty {
            explanation += "**Inputs not used:**\n"
            for input in unusedInputs {
                explanation += "- \(input)\n"
            }
        }
        
        return SuggestionExplanation(
            explanation: explanation,
            clauses: executedNodes.compactMap { nodeId in
                ko.dagNodes.first(where: { $0.id == nodeId })?.clause
            },
            inputsUsed: inputs,
            inputsNotUsed: Array(unusedInputs)
        )
    }
    
    private static func formatValue(_ value: AnyCodable) -> String {
        switch value.value {
        case let string as String:
            return string
        case let number as Double:
            return String(number)
        case let bool as Bool:
            return String(bool)
        default:
            return "\(value.value)"
        }
    }
}

public struct SuggestionExplanation: Codable {
    public let explanation: String
    public let clauses: [Clause]
    public let inputsUsed: [String: AnyCodable]
    public let inputsNotUsed: [String]
}
