// Semantic Role Mapper: Maps natural language to semantic roles, data types, and jurisdictions
import Foundation

/// Maps natural language and context to semantic roles, data types, and jurisdictions
public actor SemanticRoleMapper {
    
    public init() {}
    
    /// Map a role string to SemanticRole
    public func mapRole(_ roleString: String) -> SemanticRole? {
        let lower = roleString.lowercased()
        
        switch lower {
        case "data subject", "user", "person", "individual", "subject":
            return .dataSubject
        case "controller", "data controller", "organization", "company", "service":
            return .controller
        case "processor", "data processor", "third party", "vendor":
            return .processor
        case "agent", "ai agent", "assistant", "bot":
            return .agent
        case "system", "platform", "service":
            return .system
        default:
            return nil
        }
    }
    
    /// Map a data type string to DataType
    public func mapDataType(_ typeString: String) -> DataType? {
        let lower = typeString.lowercased()
        
        switch lower {
        case "personal data", "personal information", "pii", "personally identifiable":
            return .personalData
        case "metadata", "meta data", "meta information":
            return .metadata
        case "sensitive data", "sensitive information", "sensitive personal data":
            return .sensitiveData
        case "biometric data", "biometric", "biometrics", "fingerprint", "face":
            return .biometricData
        case "location data", "location", "gps", "geolocation":
            return .locationData
        default:
            return nil
        }
    }
    
    /// Map a jurisdiction string to Jurisdiction
    public func mapJurisdiction(_ jurisdictionString: String) -> Jurisdiction? {
        let upper = jurisdictionString.uppercased()
        
        switch upper {
        case "GDPR", "EU", "EUROPEAN UNION", "EU GDPR":
            return .GDPR
        case "CCPA", "CALIFORNIA", "CALIFORNIA CONSUMER PRIVACY ACT":
            return .CCPA
        case "PIPEDA", "CANADA", "CANADIAN":
            return .PIPEDA
        case "LGPD", "BRAZIL", "BRAZILIAN":
            return .LGPD
        default:
            return .custom(jurisdictionString)
        }
    }
    
    /// Extract semantic roles from text
    public func extractRoles(from text: String) -> [SemanticRole] {
        var roles: [SemanticRole] = []
        let lower = text.lowercased()
        
        // Look for role mentions
        let rolePatterns: [(String, SemanticRole)] = [
            ("data subject", .dataSubject),
            ("user", .user),
            ("controller", .controller),
            ("processor", .processor),
            ("agent", .agent),
            ("system", .system)
        ]
        
        for (pattern, role) in rolePatterns {
            if lower.contains(pattern) && !roles.contains(role) {
                roles.append(role)
            }
        }
        
        return roles
    }
    
    /// Extract data types from text
    public func extractDataTypes(from text: String) -> [DataType] {
        var types: [DataType] = []
        let lower = text.lowercased()
        
        let typePatterns: [(String, DataType)] = [
            ("personal data", .personalData),
            ("personal information", .personalData),
            ("pii", .personalData),
            ("metadata", .metadata),
            ("sensitive data", .sensitiveData),
            ("biometric", .biometricData),
            ("location data", .locationData),
            ("gps", .locationData)
        ]
        
        for (pattern, type) in typePatterns {
            if lower.contains(pattern) && !types.contains(type) {
                types.append(type)
            }
        }
        
        return types
    }
    
    /// Extract jurisdiction from text
    public func extractJurisdiction(from text: String) -> Jurisdiction? {
        let upper = text.uppercased()
        
        if upper.contains("GDPR") || upper.contains("EUROPEAN UNION") {
            return .GDPR
        }
        if upper.contains("CCPA") || upper.contains("CALIFORNIA") {
            return .CCPA
        }
        if upper.contains("PIPEDA") || upper.contains("CANADA") {
            return .PIPEDA
        }
        if upper.contains("LGPD") || upper.contains("BRAZIL") {
            return .LGPD
        }
        
        return nil
    }
    
    /// Create a complete semantic context from text
    public func createSemanticContext(from text: String) -> SemanticContext {
        let roles = extractRoles(from: text)
        let dataTypes = extractDataTypes(from: text)
        let jurisdiction = extractJurisdiction(from: text)
        
        return SemanticContext(
            roles: roles,
            dataTypes: dataTypes,
            jurisdiction: jurisdiction
        )
    }
}

// MARK: - Semantic Context

public struct SemanticContext {
    public let roles: [SemanticRole]
    public let dataTypes: [DataType]
    public let jurisdiction: Jurisdiction?
    
    public init(
        roles: [SemanticRole] = [],
        dataTypes: [DataType] = [],
        jurisdiction: Jurisdiction? = nil
    ) {
        self.roles = roles
        self.dataTypes = dataTypes
        self.jurisdiction = jurisdiction
    }
}
