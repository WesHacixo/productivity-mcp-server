// KO Monitoring: Performance monitoring and metrics for Kernel Object execution
import Foundation

/// Performance metrics for KO execution
public struct KOMetrics: Codable {
    public let koId: String
    public let executionTime: TimeInterval
    public let nodeCount: Int
    public let completedNodes: Int
    public let failedNodes: Int
    public let retryCount: Int
    public let entropy: Double
    public let flowCost: Double?
    public let cacheHits: Int
    public let cacheMisses: Int
    
    public init(
        koId: String,
        executionTime: TimeInterval,
        nodeCount: Int,
        completedNodes: Int,
        failedNodes: Int,
        retryCount: Int,
        entropy: Double,
        flowCost: Double? = nil,
        cacheHits: Int = 0,
        cacheMisses: Int = 0
    ) {
        self.koId = koId
        self.executionTime = executionTime
        self.nodeCount = nodeCount
        self.completedNodes = completedNodes
        self.failedNodes = failedNodes
        self.retryCount = retryCount
        self.entropy = entropy
        self.flowCost = flowCost
        self.cacheHits = cacheHits
        self.cacheMisses = cacheMisses
    }
    
    public var successRate: Double {
        guard nodeCount > 0 else { return 0.0 }
        return Double(completedNodes) / Double(nodeCount)
    }
    
    public var averageNodeTime: TimeInterval {
        guard completedNodes > 0 else { return 0.0 }
        return executionTime / Double(completedNodes)
    }
}

/// Performance monitor for KO execution
public actor KOMonitor {
    private var metricsHistory: [KOMetrics] = []
    private var activeExecutions: [String: Date] = [:] // koId -> startTime
    private let maxHistorySize = 1000
    
    public init() {}
    
    /// Start monitoring an execution
    public func startExecution(_ koId: String) {
        activeExecutions[koId] = Date()
    }
    
    /// End monitoring and record metrics
    public func endExecution(
        koId: String,
        result: KOExecutionResult,
        flowCost: Double? = nil
    ) {
        guard let startTime = activeExecutions[koId] else { return }
        activeExecutions.removeValue(forKey: koId)
        
        let executionTime = Date().timeIntervalSince(startTime)
        let completedNodes = result.executionState.completedNodes.count
        let failedNodes = result.executionState.events.filter { $0.type == .nodeFailed }.count
        
        let metrics = KOMetrics(
            koId: koId,
            executionTime: executionTime,
            nodeCount: result.executionState.events.filter { $0.type == .nodeStarted }.count,
            completedNodes: completedNodes,
            failedNodes: failedNodes,
            retryCount: result.executionState.retryCount,
            entropy: result.executionState.entropy,
            flowCost: flowCost
        )
        
        metricsHistory.append(metrics)
        
        // Prune old history
        if metricsHistory.count > maxHistorySize {
            metricsHistory.removeFirst()
        }
    }
    
    /// Get metrics for a KO
    public func getMetrics(for koId: String) -> [KOMetrics] {
        return metricsHistory.filter { $0.koId == koId }
    }
    
    /// Get recent metrics
    public func getRecentMetrics(limit: Int = 100) -> [KOMetrics] {
        return Array(metricsHistory.suffix(limit))
    }
    
    /// Get average execution time for a KO type
    public func getAverageExecutionTime(for type: OrchestrationType) -> TimeInterval {
        // In real implementation, would filter by KO type
        guard !metricsHistory.isEmpty else { return 0.0 }
        let total = metricsHistory.reduce(0.0) { $0 + $1.executionTime }
        return total / Double(metricsHistory.count)
    }
    
    /// Get success rate
    public func getSuccessRate() -> Double {
        guard !metricsHistory.isEmpty else { return 0.0 }
        let total = metricsHistory.reduce(0.0) { $0 + $1.successRate }
        return total / Double(metricsHistory.count)
    }
}

/// Comprehensive logging for KO execution
public actor KOLogger {
    private var logs: [KOLogEntry] = []
    private let maxLogSize = 5000
    
    public enum LogLevel: String, Codable {
        case debug
        case info
        case warning
        case error
    }
    
    public init() {}
    
    /// Log an event
    public func log(
        level: LogLevel,
        message: String,
        koId: String? = nil,
        nodeId: String? = nil,
        data: [String: String]? = nil
    ) {
        let entry = KOLogEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            level: level,
            message: message,
            koId: koId,
            nodeId: nodeId,
            data: data
        )
        
        logs.append(entry)
        
        // Prune old logs
        if logs.count > maxLogSize {
            logs.removeFirst()
        }
        
        // Also print for debugging (in production, would use proper logging framework)
        print("[\(level.rawValue.uppercased())] \(message)")
    }
    
    /// Get logs for a KO
    public func getLogs(for koId: String, limit: Int = 100) -> [KOLogEntry] {
        return logs.filter { $0.koId == koId }.suffix(limit)
    }
    
    /// Get recent logs
    public func getRecentLogs(level: LogLevel? = nil, limit: Int = 100) -> [KOLogEntry] {
        var filtered = logs
        if let level = level {
            filtered = filtered.filter { $0.level == level }
        }
        return Array(filtered.suffix(limit))
    }
    
    /// Clear logs
    public func clear() {
        logs.removeAll()
    }
}

public struct KOLogEntry: Codable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let level: KOLogger.LogLevel
    public let message: String
    public let koId: String?
    public let nodeId: String?
    public let data: [String: String]?
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: KOLogger.LogLevel,
        message: String,
        koId: String? = nil,
        nodeId: String? = nil,
        data: [String: String]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.koId = koId
        self.nodeId = nodeId
        self.data = data
    }
}
