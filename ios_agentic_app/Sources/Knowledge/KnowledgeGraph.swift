// Knowledge graph: entity-relationship graph for structured knowledge
import Foundation

public actor KnowledgeGraph {
    private var nodes: [UUID: KnowledgeNode] = [:]
    private var edges: [UUID: [Edge]] = [:]
    
    public init() {}
    
    /// Add knowledge nodes to graph
    public func addNodes(_ items: [KnowledgeItem]) async {
        for item in items {
            let node = KnowledgeNode(
                id: item.id,
                item: item,
                createdAt: Date()
            )
            nodes[item.id] = node
        }
    }
    
    /// Add edges between nodes
    public func addEdges(from source: String, to items: [KnowledgeItem]) async {
        // Create or find source node
        let sourceId = await findOrCreateNode(for: source)
        
        for item in items {
            let edge = Edge(
                from: sourceId,
                to: item.id,
                type: .related,
                strength: 1.0,
                createdAt: Date()
            )
            
            if edges[sourceId] == nil {
                edges[sourceId] = []
            }
            edges[sourceId]?.append(edge)
        }
    }
    
    /// Find related nodes
    public func findRelated(to query: String, limit: Int) async -> [KnowledgeItem] {
        // Find nodes matching query
        let matchingNodes = nodes.values.filter { node in
            node.item.title.localizedCaseInsensitiveContains(query) ||
            node.item.content.localizedCaseInsensitiveContains(query)
        }
        
        // Find connected nodes
        var related: Set<UUID> = []
        for node in matchingNodes {
            if let connected = edges[node.id] {
                for edge in connected {
                    related.insert(edge.to)
                }
            }
        }
        
        // Return knowledge items
        return related.compactMap { id in
            nodes[id]?.item
        }.prefix(limit).map { $0 }
    }
    
    /// Traverse graph from a node
    public func traverse(from nodeId: UUID, depth: Int = 2) async -> [KnowledgeItem] {
        var visited: Set<UUID> = []
        var result: [KnowledgeItem] = []
        var queue: [(UUID, Int)] = [(nodeId, 0)]
        
        while !queue.isEmpty {
            let (currentId, currentDepth) = queue.removeFirst()
            
            if visited.contains(currentId) || currentDepth > depth {
                continue
            }
            
            visited.insert(currentId)
            
            if let node = nodes[currentId] {
                result.append(node.item)
            }
            
            if let connected = edges[currentId], currentDepth < depth {
                for edge in connected {
                    queue.append((edge.to, currentDepth + 1))
                }
            }
        }
        
        return result
    }
    
    private func findOrCreateNode(for query: String) async -> UUID {
        // Try to find existing node
        if let existing = nodes.values.first(where: { $0.item.title == query }) {
            return existing.id
        }
        
        // Create new node
        let item = KnowledgeItem(
            title: query,
            summary: query,
            content: query,
            source: .userInput
        )
        let node = KnowledgeNode(id: item.id, item: item, createdAt: Date())
        nodes[item.id] = node
        return item.id
    }
}

struct KnowledgeNode {
    let id: UUID
    let item: KnowledgeItem
    let createdAt: Date
}

struct Edge {
    let from: UUID
    let to: UUID
    let type: Relationship.RelationshipType
    let strength: Double
    let createdAt: Date
}
