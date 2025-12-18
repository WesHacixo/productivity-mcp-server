// Pattern Learner: identifies and learns from user behavior patterns
import Foundation

/// Learns patterns from user behavior to provide intelligent suggestions
public actor PatternLearner {
    private var actionHistory: [UserAction] = []
    private var identifiedPatterns: [UserPattern] = []
    private let maxHistorySize = 1000
    
    public init() {}
    
    /// Record a user action for pattern learning
    public func recordAction(_ action: UserAction, context: ReasoningContext) async {
        actionHistory.append(action)
        
        // Keep history size manageable
        if actionHistory.count > maxHistorySize {
            actionHistory.removeFirst(actionHistory.count - maxHistorySize)
        }
        
        // Analyze for new patterns
        await analyzeForPatterns()
    }
    
    /// Identify patterns relevant to current context
    public func identifyPatterns(context: ReasoningContext) async -> [UserPattern] {
        // Filter patterns by context relevance
        return identifiedPatterns.filter { pattern in
            isPatternRelevant(pattern, to: context)
        }
    }
    
    /// Get all patterns within a time range
    public func getPatterns(timeRange: TimeRange) async -> [UserPattern] {
        let cutoffDate = dateForTimeRange(timeRange)
        return identifiedPatterns.filter { pattern in
            pattern.lastSeen >= cutoffDate
        }
    }
    
    // MARK: - Private Methods
    
    private func analyzeForPatterns() async {
        // Group actions by type and entity
        var actionGroups: [String: [UserAction]] = [:]
        
        for action in actionHistory {
            let key = "\(action.type)-\(action.entity)"
            if actionGroups[key] == nil {
                actionGroups[key] = []
            }
            actionGroups[key]?.append(action)
        }
        
        // Identify patterns
        for (key, actions) in actionGroups {
            if actions.count >= 3 { // Minimum for a pattern
                let pattern = await extractPattern(from: actions, key: key)
                if let pattern = pattern {
                    await updateOrAddPattern(pattern)
                }
            }
        }
    }
    
    private func extractPattern(from actions: [UserAction], key: String) async -> UserPattern? {
        guard let firstAction = actions.first else { return nil }
        
        // Analyze frequency
        let frequency = calculateFrequency(actions)
        
        // Analyze time patterns
        let timePattern = analyzeTimePattern(actions)
        
        // Calculate confidence based on consistency
        let confidence = calculateConfidence(actions)
        
        // Determine pattern type
        let patternType = determinePatternType(firstAction.type)
        
        return UserPattern(
            type: patternType,
            entity: firstAction.entity,
            frequency: frequency,
            timePattern: timePattern,
            confidence: confidence,
            firstSeen: actions.first!.timestamp,
            lastSeen: actions.last!.timestamp,
            count: actions.count
        )
    }
    
    private func calculateFrequency(_ actions: [UserAction]) -> Int {
        // Count occurrences per week
        let calendar = Calendar.current
        var weekCounts: [Int: Int] = [:]
        
        for action in actions {
            let week = calendar.component(.weekOfYear, from: action.timestamp)
            weekCounts[week, default: 0] += 1
        }
        
        return weekCounts.values.reduce(0, +) / max(weekCounts.count, 1)
    }
    
    private func analyzeTimePattern(_ actions: [UserAction]) -> String? {
        // Find common time patterns
        let hours = actions.map { Calendar.current.component(.hour, from: $0.timestamp) }
        let hourCounts = Dictionary(grouping: hours, by: { $0 })
            .mapValues { $0.count }
        
        if let mostCommonHour = hourCounts.max(by: { $0.value < $1.value }) {
            if mostCommonHour.value >= actions.count / 2 {
                return "\(mostCommonHour.key):00"
            }
        }
        
        return nil
    }
    
    private func calculateConfidence(_ actions: [UserAction]) -> Double {
        // Confidence based on consistency and frequency
        let consistency = calculateConsistency(actions)
        let frequencyScore = min(Double(actions.count) / 10.0, 1.0)
        
        return (consistency * 0.6) + (frequencyScore * 0.4)
    }
    
    private func calculateConsistency(_ actions: [UserAction]) -> Double {
        // Measure how consistent the timing is
        guard actions.count >= 2 else { return 0.0 }
        
        let intervals = zip(actions, actions.dropFirst())
            .map { $0.1.timestamp.timeIntervalSince($0.0.timestamp) }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)
        
        // Lower variance = higher consistency
        let consistency = 1.0 - min(stdDev / (avgInterval * 2), 1.0)
        return max(0.0, consistency)
    }
    
    private func determinePatternType(_ actionType: UserAction.ActionType) -> UserPattern.PatternType {
        switch actionType {
        case .schedule, .reschedule:
            return .scheduling
        case .createTask:
            return .taskCreation
        case .completeTask:
            return .taskCompletion
        case .delete:
            return .deletion
        }
    }
    
    private func updateOrAddPattern(_ pattern: UserPattern) async {
        if let index = identifiedPatterns.firstIndex(where: { $0.entity == pattern.entity && $0.type == pattern.type }) {
            // Update existing pattern
            identifiedPatterns[index] = pattern
        } else {
            // Add new pattern
            identifiedPatterns.append(pattern)
        }
    }
    
    private func isPatternRelevant(_ pattern: UserPattern, to context: ReasoningContext) -> Bool {
        // Check if pattern matches current context
        switch context.intent {
        case .create:
            return pattern.type == .taskCreation || pattern.type == .scheduling
        case .retrieve:
            return true // All patterns potentially relevant
        case .update:
            return pattern.type == .scheduling
        default:
            return false
        }
    }
    
    private func dateForTimeRange(_ range: TimeRange) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
}

// MARK: - Supporting Types

public struct UserPattern: Identifiable {
    public let id = UUID()
    public let type: PatternType
    public let entity: String
    public let frequency: Int // occurrences per week
    public let timePattern: String? // e.g., "14:00" for 2pm
    public let confidence: Double
    public let firstSeen: Date
    public let lastSeen: Date
    public let count: Int
    
    public enum PatternType {
        case scheduling
        case taskCreation
        case taskCompletion
        case timePreference
        case deletion
    }
}
