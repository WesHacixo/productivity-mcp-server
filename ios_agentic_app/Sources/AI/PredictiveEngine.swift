// Predictive Engine: anticipates user needs based on patterns and context
import Foundation

/// Predicts user needs and suggests proactive actions
public actor PredictiveEngine {
    private let patternLearner: PatternLearner
    private var predictionHistory: [Prediction] = []
    private var workflowWarmer: WorkflowWarmer?
    
    public init(patternLearner: PatternLearner, workflowWarmer: WorkflowWarmer? = nil) {
        self.patternLearner = patternLearner
        self.workflowWarmer = workflowWarmer
    }
    
    /// Set workflow warmer for predictive caching (called after initialization)
    public func setWorkflowWarmer(_ warmer: WorkflowWarmer) async {
        self.workflowWarmer = warmer
    }
    
    /// Predict user needs based on context
    public func predict(context: ReasoningContext) async -> [Prediction] {
        var predictions: [Prediction] = []
        
        // 1. Time-based predictions
        let timePredictions = await predictFromTime(context: context)
        predictions.append(contentsOf: timePredictions)
        
        // 2. Pattern-based predictions
        let patterns = await patternLearner.identifyPatterns(context: context)
        for pattern in patterns {
            if let prediction = await predictFromPattern(pattern, context: context) {
                predictions.append(prediction)
            }
        }
        
        // 3. Context-based predictions
        let contextPredictions = await predictFromContext(context: context)
        predictions.append(contentsOf: contextPredictions)
        
        let sorted = predictions.sorted { $0.confidence > $1.confidence }
        
        // 4. Warm workflows for high-confidence predictions
        if let warmer = workflowWarmer {
            await warmer.warmWorkflows(for: sorted.filter { $0.confidence > 0.7 })
        }
        
        return sorted
    }
    
    /// Update predictions based on user action
    public func updateFromAction(_ action: UserAction, context: ReasoningContext) async {
        // Validate previous predictions
        await validatePredictions(against: action)
        
        // Learn from action
        await learnFromAction(action, context: context)
    }
    
    // MARK: - Private Methods
    
    private func predictFromTime(context: ReasoningContext) async -> [Prediction] {
        var predictions: [Prediction] = []
        let hour = Calendar.current.component(.hour, from: Date())
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        
        // Morning predictions
        if hour >= 7 && hour < 9 {
            predictions.append(Prediction(
                type: .task,
                title: "Morning planning",
                description: "You typically review your schedule in the morning",
                suggestedAction: "Show today's schedule",
                confidence: 0.75,
                reasoning: "Based on time of day pattern"
            ))
        }
        
        // Afternoon predictions
        if hour >= 13 && hour < 15 {
            predictions.append(Prediction(
                type: .optimization,
                title: "Afternoon review",
                description: "Good time to check on pending tasks",
                suggestedAction: "Show pending tasks",
                confidence: 0.65,
                reasoning: "Based on typical afternoon activity"
            ))
        }
        
        // End of day predictions
        if hour >= 17 && hour < 19 {
            predictions.append(Prediction(
                type: .scheduling,
                title: "Evening planning",
                description: "You often plan tomorrow's schedule in the evening",
                suggestedAction: "Show tomorrow's schedule",
                confidence: 0.70,
                reasoning: "Based on end-of-day pattern"
            ))
        }
        
        // Day of week predictions
        if dayOfWeek == 1 { // Monday
            predictions.append(Prediction(
                type: .task,
                title: "Week planning",
                description: "Start of week - good time to plan ahead",
                suggestedAction: "Show week view",
                confidence: 0.80,
                reasoning: "Monday is typically a planning day"
            ))
        }
        
        return predictions
    }
    
    private func predictFromPattern(
        _ pattern: UserPattern,
        context: ReasoningContext
    ) async -> Prediction? {
        // Predict based on pattern
        switch pattern.type {
        case .scheduling:
            // If it's around the usual time for this pattern
            if isPatternTime(pattern) {
                return Prediction(
                    type: .scheduling,
                    title: "Recurring schedule",
                    description: "You usually schedule '\(pattern.entity)' around this time",
                    suggestedAction: "Schedule \(pattern.entity)",
                    confidence: pattern.confidence,
                    reasoning: "Based on your scheduling pattern"
                )
            }
        case .taskCreation:
            return Prediction(
                type: .task,
                title: "Recurring task",
                description: "You often create tasks like '\(pattern.entity)'",
                suggestedAction: "Create task: \(pattern.entity)",
                confidence: pattern.confidence * 0.8,
                reasoning: "Based on your task creation pattern"
            )
        default:
            return nil
        }
        
        return nil
    }
    
    private func predictFromContext(context: ReasoningContext) async -> [Prediction] {
        var predictions: [Prediction] = []
        
        // If user is creating something, predict they might want to schedule it
        if context.intent == .create {
            predictions.append(Prediction(
                type: .scheduling,
                title: "Schedule this?",
                description: "You might want to schedule what you're creating",
                suggestedAction: "Schedule",
                confidence: 0.6,
                reasoning: "Based on current action context"
            ))
        }
        
        // If user is retrieving, predict they might want to update
        if context.intent == .retrieve {
            predictions.append(Prediction(
                type: .optimization,
                title: "Update or reschedule?",
                description: "You might want to modify what you're viewing",
                suggestedAction: "Show options",
                confidence: 0.5,
                reasoning: "Based on viewing context"
            ))
        }
        
        return predictions
    }
    
    private func isPatternTime(_ pattern: UserPattern) -> Bool {
        guard let timePattern = pattern.timePattern else { return false }
        
        // Extract hour from pattern (e.g., "14:00" -> 14)
        let hourString = timePattern.components(separatedBy: ":").first ?? ""
        guard let patternHour = Int(hourString) else { return false }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Consider it pattern time if within 1 hour
        return abs(currentHour - patternHour) <= 1
    }
    
    private func validatePredictions(against action: UserAction) async {
        // Check if any predictions matched the action
        for (index, prediction) in predictionHistory.enumerated() {
            if predictionMatchesAction(prediction, action: action) {
                // Prediction was accurate - increase confidence for similar predictions
                // (In a real implementation, we'd update the prediction model)
            }
        }
    }
    
    private func predictionMatchesAction(_ prediction: Prediction, action: UserAction) -> Bool {
        // Simple matching - in reality, would use more sophisticated matching
        return prediction.suggestedAction.localizedCaseInsensitiveContains(action.entity)
    }
    
    private func learnFromAction(_ action: UserAction, context: ReasoningContext) async {
        // Store prediction for future validation
        // In a real implementation, this would update a learning model
    }
}

// MARK: - Supporting Types

public struct Prediction: Identifiable {
    public let id = UUID()
    public let type: PredictionType
    public let title: String
    public let description: String
    public let suggestedAction: String
    public let confidence: Double
    public let reasoning: String
    
    public enum PredictionType {
        case scheduling
        case task
        case optimization
        case reminder
    }
}
