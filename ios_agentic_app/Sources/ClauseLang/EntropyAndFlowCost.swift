// Entropy Caps & Flow-Cost Objective: Prevent over-optimization and reduce context switching
import Foundation

/// Tracks entropy (rescheduling churn) and enforces caps
public actor EntropyTracker {
    private var entropyHistory: [EntropyMeasurement] = []
    private var currentEntropy: Double = 0.0
    private let maxHistorySize = 100
    
    public init() {}
    
    /// Record a rescheduling action and update entropy
    public func recordRescheduling(
        action: String,
        affectedBlocks: Int,
        totalBlocks: Int
    ) {
        // Calculate entropy: ratio of affected blocks to total blocks
        let blockRatio = Double(affectedBlocks) / Double(max(totalBlocks, 1))
        
        // Weight by action type
        let weight: Double
        switch action {
        case "reshuffle_all": weight = 1.0
        case "local_adaptation": weight = 0.1
        case "insert_block": weight = 0.05
        default: weight = 0.5
        }
        
        let entropy = blockRatio * weight
        
        // Update current entropy (exponential moving average)
        currentEntropy = (currentEntropy * 0.7) + (entropy * 0.3)
        
        // Record measurement
        let measurement = EntropyMeasurement(
            timestamp: Date(),
            entropy: entropy,
            cumulativeEntropy: currentEntropy,
            action: action,
            affectedBlocks: affectedBlocks,
            totalBlocks: totalBlocks
        )
        
        entropyHistory.append(measurement)
        
        // Prune old history
        if entropyHistory.count > maxHistorySize {
            entropyHistory.removeFirst()
        }
    }
    
    /// Check if entropy cap is exceeded
    public func isCapExceeded(cap: Double) -> Bool {
        return currentEntropy > cap
    }
    
    /// Get current entropy
    public func getCurrentEntropy() -> Double {
        return currentEntropy
    }
    
    /// Reset entropy
    public func reset() {
        currentEntropy = 0.0
        entropyHistory.removeAll()
    }
    
    /// Get entropy history
    public func getHistory() -> [EntropyMeasurement] {
        return entropyHistory
    }
}

/// Flow-Cost Objective: Reduces context switching by clustering and penalizing fragmentation
public actor FlowCostOptimizer {
    private var contextSwitchCount: Int = 0
    private var taskFragmentation: [String: Int] = [:] // task_id -> fragment_count
    
    public init() {}
    
    /// Calculate flow cost for a schedule
    public func calculateFlowCost(
        blocks: [ScheduleBlock],
        cognitiveModes: [String: String] = [:]
    ) -> FlowCost {
        var totalCost: Double = 0.0
        var switchCount = 0
        var fragmentationPenalty: Double = 0.0
        
        // Count context switches
        var previousMode: String? = nil
        for block in blocks {
            let mode = cognitiveModes[block.id] ?? "general"
            if let prev = previousMode, prev != mode {
                switchCount += 1
                totalCost += getSwitchCost(from: prev, to: mode)
            }
            previousMode = mode
        }
        
        // Calculate fragmentation penalty
        for (taskId, fragmentCount) in taskFragmentation {
            if fragmentCount > 1 {
                fragmentationPenalty += Double(fragmentCount - 1) * 0.5
            }
        }
        
        totalCost += fragmentationPenalty
        
        return FlowCost(
            totalCost: totalCost,
            switchCount: switchCount,
            fragmentationPenalty: fragmentationPenalty,
            blocks: blocks.count
        )
    }
    
    /// Record task fragmentation
    public func recordFragmentation(taskId: String, fragmentCount: Int) {
        taskFragmentation[taskId] = fragmentCount
    }
    
    /// Cluster tasks by cognitive mode to reduce switches
    public func clusterByCognitiveMode(
        tasks: [TaskItem],
        cognitiveModes: [String: String]
    ) -> [[TaskItem]] {
        var clusters: [String: [TaskItem]] = [:]
        
        for task in tasks {
            let mode = cognitiveModes[task.id] ?? "general"
            if clusters[mode] == nil {
                clusters[mode] = []
            }
            clusters[mode]?.append(task)
        }
        
        return Array(clusters.values)
    }
    
    /// Check if block meets minimum size requirement
    public func meetsMinimumBlockSize(
        block: ScheduleBlock,
        minDuration: Int = 30
    ) -> Bool {
        return block.durationMinutes >= minDuration
    }
    
    /// Penalize fragmentation
    public func penalizeFragmentation(
        taskCount: Int,
        blockDuration: Int
    ) -> Double {
        // High penalty if many tasks in short block
        if taskCount > 3 && blockDuration < 30 {
            return 1.0 // High penalty
        }
        if taskCount > 2 && blockDuration < 20 {
            return 0.5 // Medium penalty
        }
        return 0.0 // No penalty
    }
    
    /// Reset flow cost state
    public func reset() {
        contextSwitchCount = 0
        taskFragmentation.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func getSwitchCost(from: String, to: String) -> Double {
        // Different cognitive modes have different switch costs
        let modePairs: [String: Double] = [
            "creative->admin": 1.0,
            "admin->creative": 1.0,
            "creative->general": 0.5,
            "general->creative": 0.5,
            "admin->general": 0.3,
            "general->admin": 0.3
        ]
        
        let key = "\(from)->\(to)"
        return modePairs[key] ?? 0.2 // Default low cost
    }
}

// MARK: - Supporting Types

public struct EntropyMeasurement: Codable {
    public let timestamp: Date
    public let entropy: Double
    public let cumulativeEntropy: Double
    public let action: String
    public let affectedBlocks: Int
    public let totalBlocks: Int
}

public struct FlowCost: Codable {
    public let totalCost: Double
    public let switchCount: Int
    public let fragmentationPenalty: Double
    public let blocks: Int
    
    public var normalizedCost: Double {
        // Normalize by number of blocks
        return blocks > 0 ? totalCost / Double(blocks) : totalCost
    }
}

public struct ScheduleBlock: Codable, Identifiable {
    public let id: String
    public let startTime: Date
    public let durationMinutes: Int
    public let tasks: [String] // Task IDs
    public let cognitiveMode: String?
    
    public init(
        id: String = UUID().uuidString,
        startTime: Date,
        durationMinutes: Int,
        tasks: [String] = [],
        cognitiveMode: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.tasks = tasks
        self.cognitiveMode = cognitiveMode
    }
}

public struct TaskItem: Codable, Identifiable {
    public let id: String
    public let title: String
    public let type: TaskType
    public let cognitiveMode: String?
    
    public enum TaskType: String, Codable {
        case creative
        case admin
        case errand
        case meeting
        case general
    }
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        type: TaskType,
        cognitiveMode: String? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.cognitiveMode = cognitiveMode
    }
}

/// Entropy Cap Enforcer - Enforces entropy caps in KO execution
public actor EntropyCapEnforcer {
    private let entropyTracker: EntropyTracker
    private let flowCostOptimizer: FlowCostOptimizer
    
    public init(
        entropyTracker: EntropyTracker,
        flowCostOptimizer: FlowCostOptimizer
    ) {
        self.entropyTracker = entropyTracker
        self.flowCostOptimizer = flowCostOptimizer
    }
    
    /// Check if KO execution should be frozen due to entropy cap
    public func shouldFreeze(
        ko: KernelObject,
        currentEntropy: Double
    ) -> Bool {
        guard let loop = ko.loop, let cap = loop.entropyCap else {
            return false
        }
        
        return currentEntropy > cap
    }
    
    /// Request user decision when entropy cap is reached
    public func requestUserDecision(
        reason: String,
        options: [String]
    ) -> UserDecisionRequest {
        return UserDecisionRequest(
            reason: reason,
            options: options,
            timestamp: Date()
        )
    }
    
    /// Evaluate flow cost and apply penalties
    public func evaluateFlowCost(
        blocks: [ScheduleBlock],
        cognitiveModes: [String: String] = [:]
    ) async -> FlowCost {
        return await flowCostOptimizer.calculateFlowCost(
            blocks: blocks,
            cognitiveModes: cognitiveModes
        )
    }
}

public struct UserDecisionRequest: Codable {
    public let reason: String
    public let options: [String]
    public let timestamp: Date
}
