// Vector memory: semantic search with embeddings (MLX-ready)
import Foundation

public actor VectorMemory {
    private var items: [KnowledgeItem] = []
    private var embeddings: [UUID: [Float]] = [:]
    private let persistenceURL: URL
    
    // TODO: MLX embedding model integration
    // private let embeddingModel: MLXEmbeddingModel?
    
    public init(persistenceURL: URL? = nil) {
        if let url = persistenceURL {
            self.persistenceURL = url
        } else {
            self.persistenceURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("vector_memory.json")
        }
        Task { await load() }
    }
    
    /// Add knowledge item with embedding
    public func add(_ item: KnowledgeItem) async {
        items.append(item)
        
        // Generate embedding
        let embedding = await generateEmbedding(for: item.content)
        embeddings[item.id] = embedding
        
        await save()
    }
    
    /// Semantic search
    public func search(query: String, limit: Int = 10) async -> [KnowledgeItem] {
        // Generate query embedding
        let queryEmbedding = await generateEmbedding(for: query)
        
        // Compute similarities
        var scored: [(KnowledgeItem, Double)] = []
        
        for item in items {
            if let itemEmbedding = embeddings[item.id] {
                let similarity = cosineSimilarity(queryEmbedding, itemEmbedding)
                scored.append((item, similarity))
            }
        }
        
        // Sort by similarity and return top results
        scored.sort { $0.1 > $1.1 }
        return Array(scored.prefix(limit).map { $0.0 })
    }
    
    private let mlxEmbeddings: MLXEmbeddings?
    
    public init(persistenceURL: URL? = nil, mlxEmbeddings: MLXEmbeddings? = nil) {
        if let url = persistenceURL {
            self.persistenceURL = url
        } else {
            self.persistenceURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("vector_memory.json")
        }
        self.mlxEmbeddings = mlxEmbeddings
        Task { await load() }
    }
    
    /// Generate embedding for text using MLX
    private func generateEmbedding(for text: String) async -> [Float] {
        if let mlx = mlxEmbeddings {
            do {
                return try await mlx.embed(text)
            } catch {
                // Fallback to placeholder
                return await generatePlaceholderEmbedding(text)
            }
        }
        return await generatePlaceholderEmbedding(text)
    }
    
    private func generatePlaceholderEmbedding(_ text: String) async -> [Float] {
        // Placeholder until MLX is integrated
        let hash = text.hashValue
        var embedding = [Float](repeating: 0, count: 384) // Standard embedding size
        for i in 0..<min(embedding.count, 32) {
            embedding[i] = Float((hash >> i) & 1) * 0.5
        }
        return embedding
    }
    
    /// Cosine similarity between two embeddings
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return 0.0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator > 0 else { return 0.0 }
        
        return Double(dotProduct / denominator)
    }
    
    private func load() async {
        // TODO: Load persisted items and embeddings
    }
    
    private func save() async {
        // TODO: Persist items and embeddings
    }
}
