// ClauseLang Storage: YAML/JSON storage and modular policy skeleton management
import Foundation

/// Manages storage and retrieval of ClauseLang policies in YAML/JSON formats
public actor ClauseLangStorage {
    private let baseURL: URL
    private let fileManager = FileManager.default
    
    public init(baseURL: URL? = nil) {
        if let url = baseURL {
            self.baseURL = url
        } else {
            // Default to Documents/ClauseLang
            self.baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ClauseLang")
        }
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: self.baseURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Policy Document Storage
    
    /// Save a policy document to JSON
    public func savePolicyDocument(_ document: PolicyDocument, filename: String? = nil) throws {
        let name = filename ?? "policy-\(document.id).json"
        let url = baseURL.appendingPathComponent(name)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(document)
        try data.write(to: url, options: [.atomic])
    }
    
    /// Load a policy document from JSON
    public func loadPolicyDocument(filename: String) throws -> PolicyDocument {
        let url = baseURL.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(PolicyDocument.self, from: data)
    }
    
    /// List all policy documents
    public func listPolicyDocuments() throws -> [String] {
        let files = try fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
        return files
            .filter { $0.pathExtension == "json" }
            .map { $0.lastPathComponent }
    }
    
    // MARK: - Contract Primitive Storage
    
    /// Save a contract primitive to JSON
    public func saveContract(_ contract: ContractPrimitive, filename: String? = nil) throws {
        let name = filename ?? "contract-\(contract.id).json"
        let url = baseURL.appendingPathComponent(name)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(contract)
        try data.write(to: url, options: [.atomic])
    }
    
    /// Load a contract primitive from JSON
    public func loadContract(filename: String) throws -> ContractPrimitive {
        let url = baseURL.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ContractPrimitive.self, from: data)
    }
    
    // MARK: - Clause Storage (Modular)
    
    /// Save a clause to a modular file
    public func saveClause(_ clause: Clause, in directory: String = "clauses") throws {
        let clausesDir = baseURL.appendingPathComponent(directory)
        try fileManager.createDirectory(at: clausesDir, withIntermediateDirectories: true)
        
        let filename = "\(clause.id).json"
        let url = clausesDir.appendingPathComponent(filename)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(clause)
        try data.write(to: url, options: [.atomic])
    }
    
    /// Load a clause from a modular file
    public func loadClause(id: String, from directory: String = "clauses") throws -> Clause {
        let clausesDir = baseURL.appendingPathComponent(directory)
        let url = clausesDir.appendingPathComponent("\(id).json")
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Clause.self, from: data)
    }
    
    /// Load all clauses from a directory
    public func loadAllClauses(from directory: String = "clauses") throws -> [Clause] {
        let clausesDir = baseURL.appendingPathComponent(directory)
        let files = try fileManager.contentsOfDirectory(at: clausesDir, includingPropertiesForKeys: nil)
        
        var clauses: [Clause] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for file in files where file.pathExtension == "json" {
            let data = try Data(contentsOf: file)
            let clause = try decoder.decode(Clause.self, from: data)
            clauses.append(clause)
        }
        
        return clauses
    }
    
    // MARK: - Policy Skeleton Management
    
    /// Create a modular policy skeleton with clause references
    public func createPolicySkeleton(
        title: String,
        parties: [SemanticRole],
        clauseReferences: [String],
        jurisdiction: Jurisdiction? = nil
    ) -> PolicyDocument {
        return PolicyDocument(
            id: "policy-\(UUID().uuidString.prefix(8))",
            title: title,
            parties: parties,
            clauseReferences: clauseReferences,
            clauses: [],
            jurisdiction: jurisdiction,
            metadata: ContractMetadata(
                version: "1.0.0",
                effectiveDate: Date(),
                source: "skeleton"
            )
        )
    }
    
    /// Resolve clause references in a policy document
    public func resolveClauseReferences(_ document: PolicyDocument) async throws -> PolicyDocument {
        var resolvedClauses: [Clause] = []
        
        // Load clauses from references
        for ref in document.clauseReferences {
            // Try to load from clauses directory
            if let clause = try? loadClause(id: ref) {
                resolvedClauses.append(clause)
            } else {
                // Try to load as filename
                if let clause = try? loadClause(id: ref.replacingOccurrences(of: ".json", with: "")) {
                    resolvedClauses.append(clause)
                }
            }
        }
        
        // Combine with inline clauses
        let allClauses = document.clauses + resolvedClauses
        
        return PolicyDocument(
            id: document.id,
            title: document.title,
            parties: document.parties,
            clauseReferences: document.clauseReferences,
            clauses: allClauses,
            jurisdiction: document.jurisdiction,
            metadata: document.metadata
        )
    }
    
    // MARK: - Export/Import
    
    /// Export policy document to JSON string
    public func exportPolicyDocument(_ document: PolicyDocument) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(document)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Import policy document from JSON string
    public func importPolicyDocument(_ jsonString: String) throws -> PolicyDocument {
        guard let data = jsonString.data(using: .utf8) else {
            throw ClauseLangStorageError.invalidEncoding
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(PolicyDocument.self, from: data)
    }
    
    /// Export contract to JSON string
    public func exportContract(_ contract: ContractPrimitive) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(contract)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Import contract from JSON string
    public func importContract(_ jsonString: String) throws -> ContractPrimitive {
        guard let data = jsonString.data(using: .utf8) else {
            throw ClauseLangStorageError.invalidEncoding
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ContractPrimitive.self, from: data)
    }
    
    // MARK: - Kernel Object Storage
    
    /// Save a Kernel Object to JSON
    public func saveKO(_ ko: KernelObject, filename: String? = nil) throws {
        let name = filename ?? "ko-\(ko.id).json"
        let url = baseURL.appendingPathComponent("kernel_objects").appendingPathComponent(name)
        
        // Create directory if needed
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(ko)
        try data.write(to: url, options: [.atomic])
    }
    
    /// Load a Kernel Object from JSON
    public func loadKO(id: String) throws -> KernelObject? {
        let url = baseURL.appendingPathComponent("kernel_objects").appendingPathComponent("ko-\(id).json")
        
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(KernelObject.self, from: data)
    }
    
    /// List all Kernel Objects
    public func listKOs() throws -> [String] {
        let koDir = baseURL.appendingPathComponent("kernel_objects")
        guard fileManager.fileExists(atPath: koDir.path) else {
            return []
        }
        
        let files = try fileManager.contentsOfDirectory(at: koDir, includingPropertiesForKeys: nil)
        return files
            .filter { $0.pathExtension == "json" }
            .map { $0.lastPathComponent.replacingOccurrences(of: "ko-", with: "").replacingOccurrences(of: ".json", with: "") }
    }
}

// MARK: - Errors

public enum ClauseLangStorageError: Error, LocalizedError {
    case invalidEncoding
    case fileNotFound
    case invalidFormat
    case directoryCreationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Invalid UTF-8 encoding"
        case .fileNotFound:
            return "File not found"
        case .invalidFormat:
            return "Invalid file format"
        case .directoryCreationFailed:
            return "Failed to create directory"
        }
    }
}
