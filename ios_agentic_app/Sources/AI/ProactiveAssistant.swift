// Proactive AI Assistant: learns patterns, predicts needs, suggests actions
// Enterprise-grade knowledge escort that anticipates user needs
import Foundation

/// Proactive AI assistant that learns from user behavior and provides intelligent suggestions
public actor ProactiveAssistant {
    private let knowledgeEscort: KnowledgeEscort
    private let memory: AgentMemory
    private let patternLearner: PatternLearner
    private let predictor: PredictiveEngine
    private let workflowWarmer: WorkflowWarmer?
    
    public init(
        knowledgeEscort: KnowledgeEscort,
        memory: AgentMemory,
        patternLearner: PatternLearner,
        predictor: PredictiveEngine,
        workflowWarmer: WorkflowWarmer? = nil
    ) {
        self.knowledgeEscort = knowledgeEscort
        self.memory = memory
        self.patternLearner = patternLearner
        self.predictor = predictor
        self.workflowWarmer = workflowWarmer
    }
    
    /// Generate proactive suggestions based on context and learned patterns
    public func generateSuggestions(context: ReasoningContext) async -> [ProactiveSuggestion] {
        var suggestions: [ProactiveSuggestion] = []
        
        // 1. Pattern-based suggestions
        let patterns = await patternLearner.identifyPatterns(context: context)
        for pattern in patterns {
            if let suggestion = await generateSuggestionFromPattern(pattern, context: context) {
                suggestions.append(suggestion)
            }
        }
        
        // 2. Predictive suggestions (this also warms workflows)
        let predictions = await predictor.predict(context: context)
        for prediction in predictions {
            if let suggestion = await generateSuggestionFromPrediction(prediction, context: context) {
                suggestions.append(suggestion)
            }
        }
        
        // 3. Knowledge-based suggestions
        let knowledgeSuggestions = await knowledgeEscort.suggest(context: context)
        for ks in knowledgeSuggestions {
            suggestions.append(ProactiveSuggestion(
                type: .knowledge,
                title: ks.title,
                description: ks.description,
                action: ks.title,
                confidence: ks.relevance,
                reasoning: "Based on your knowledge base"
            ))
        }
        
        // 4. Context-aware recommendations
        let contextSuggestions = await generateContextSuggestions(context: context)
        suggestions.append(contentsOf: contextSuggestions)
        
        // Sort by confidence and relevance
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    /// Learn from user action and update patterns
    public func learnFromAction(action: UserAction, context: ReasoningContext) async {
        await patternLearner.recordAction(action, context: context)
        await predictor.updateFromAction(action, context: context)
    }
    
    /// Generate insights about user's productivity patterns
    public func generateInsights(timeRange: TimeRange = .week) async -> [Insight] {
        let patterns = await patternLearner.getPatterns(timeRange: timeRange)
        var insights: [Insight] = []
        
        for pattern in patterns {
            let insight = await analyzePattern(pattern)
            insights.append(insight)
        }
        
        return insights.sorted { $0.importance > $1.importance }
    }
    
    /// Anticipate user needs based on current context
    public func anticipateNeeds(context: ReasoningContext) async -> [AnticipatedNeed] {
        let predictions = await predictor.predict(context: context)
        let patterns = await patternLearner.identifyPatterns(context: context)
        
        var needs: [AnticipatedNeed] = []
        
        // Combine predictions and patterns
        for prediction in predictions {
            if prediction.confidence > 0.7 {
                needs.append(AnticipatedNeed(
                    type: prediction.type,
                    description: prediction.description,
                    suggestedAction: prediction.suggestedAction,
                    confidence: prediction.confidence,
                    reasoning: prediction.reasoning
                ))
            }
        }
        
        return needs.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Private Methods
    
    private func generateSuggestionFromPattern(
        _ pattern: UserPattern,
        context: ReasoningContext
    ) async -> ProactiveSuggestion? {
        switch pattern.type {
        case .scheduling:
            return ProactiveSuggestion(
                type: .scheduling,
                title: "Schedule recurring task",
                description: "You usually schedule '\(pattern.entity)' around this time",
                action: "Schedule \(pattern.entity)",
                confidence: pattern.confidence,
                reasoning: "Based on your scheduling pattern"
            )
        case .taskCreation:
            return ProactiveSuggestion(
                type: .task,
                title: "Create similar task",
                description: "You often create tasks like '\(pattern.entity)' on \(pattern.frequency)",
                action: "Create task: \(pattern.entity)",
                confidence: pattern.confidence,
                reasoning: "Based on your task creation pattern"
            )
        case .timePreference:
            return ProactiveSuggestion(
                type: .optimization,
                title: "Optimal scheduling time",
                description: "You prefer scheduling meetings at \(pattern.entity)",
                action: "Schedule at \(pattern.entity)",
                confidence: pattern.confidence,
                reasoning: "Based on your time preferences"
            )
        default:
            return nil
        }
    }
    
    private func generateSuggestionFromPrediction(
        _ prediction: Prediction,
        context: ReasoningContext
    ) async -> ProactiveSuggestion? {
        return ProactiveSuggestion(
            type: .prediction,
            title: prediction.title,
            description: prediction.description,
            action: prediction.suggestedAction,
            confidence: prediction.confidence,
            reasoning: prediction.reasoning
        )
    }
    
    private func generateContextSuggestions(context: ReasoningContext) async -> [ProactiveSuggestion] {
        var suggestions: [ProactiveSuggestion] = []
        
        // Time-based suggestions
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 8 && hour < 10 {
            suggestions.append(ProactiveSuggestion(
                type: .optimization,
                title: "Morning planning",
                description: "Review your day and prioritize tasks",
                action: "Show today's schedule",
                confidence: 0.8,
                reasoning: "It's morning - good time to plan your day"
            ))
        }
        
        // Task-based suggestions
        if context.intent == .create {
            suggestions.append(ProactiveSuggestion(
                type: .task,
                title: "Set reminder",
                description: "Would you like to set a reminder for this?",
                action: "Set reminder",
                confidence: 0.6,
                reasoning: "You're creating something - might want a reminder"
            ))
        }
        
        return suggestions
    }
    
    private func analyzePattern(_ pattern: UserPattern) async -> Insight {
        let importance = pattern.confidence * Double(pattern.frequency)
        let description = await generateInsightDescription(pattern)
        
        return Insight(
            type: pattern.type,
            title: "Pattern detected",
            description: description,
            importance: importance,
            actionable: true,
            suggestedAction: await generateActionFromPattern(pattern)
        )
    }
    
    private func generateInsightDescription(_ pattern: UserPattern) async -> String {
        switch pattern.type {
        case .scheduling:
            return "You schedule '\(pattern.entity)' \(pattern.frequency) times per week, usually around \(pattern.timePattern ?? "similar times")"
        case .taskCreation:
            return "You create tasks like '\(pattern.entity)' regularly, suggesting this is a recurring activity"
        case .timePreference:
            return "You prefer scheduling important items at \(pattern.entity), indicating optimal productivity time"
        default:
            return "Pattern detected in your behavior"
        }
    }
    
    private func generateActionFromPattern(_ pattern: UserPattern) async -> String? {
        switch pattern.type {
        case .scheduling:
            return "Set up recurring schedule for '\(pattern.entity)'"
        case .taskCreation:
            return "Create template for '\(pattern.entity)'"
        default:
            return nil
        }
    }
}

// MARK: - Supporting Types

public struct ProactiveSuggestion: Identifiable {
    public let id = UUID()
    public let type: SuggestionType
    public let title: String
    public let description: String
    public let action: String
    public let confidence: Double
    public let reasoning: String
    
    public enum SuggestionType {
        case scheduling
        case task
        case optimization
        case knowledge
        case prediction
    }
}

public struct Insight: Identifiable {
    public let id = UUID()
    public let type: UserPattern.PatternType
    public let title: String
    public let description: String
    public let importance: Double
    public let actionable: Bool
    public let suggestedAction: String?
}

public struct AnticipatedNeed: Identifiable {
    public let id = UUID()
    public let type: Prediction.PredictionType
    public let description: String
    public let suggestedAction: String
    public let confidence: Double
    public let reasoning: String
}

public struct UserAction {
    public let type: ActionType
    public let entity: String
    public let timestamp: Date
    public let context: ReasoningContext
    
    public enum ActionType {
        case schedule
        case createTask
        case completeTask
        case reschedule
        case delete
    }
}

public enum TimeRange {
    case day
    case week
    case month
    case year
}
