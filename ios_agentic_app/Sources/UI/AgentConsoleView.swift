// SwiftUI console for interacting with the agent
import SwiftUI

final class AgentConsoleViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var messages: [AgentMessage] = []
    @Published var isProcessing: Bool = false
    @Published var reasoningTrace: ReasoningTrace?
    @Published var knowledgeSuggestions: [Suggestion] = []
    @Published var proactiveSuggestions: [ProactiveSuggestion] = []
    @Published var insights: [Insight] = []
    @Published var anticipatedNeeds: [AnticipatedNeed] = []
    @Published var showingInsights = false
    
    private let memory = AgentMemory()
    private let tools = ToolRegistry()
    private let knowledgeGraph = KnowledgeGraph()
    
    // MLX components
    private let mlxLLM = MLXLLM()
    private let mlxEmbeddings = MLXEmbeddings()
    
    // Knowledge components with MLX
    private lazy var vectorMemory = VectorMemory(mlxEmbeddings: mlxEmbeddings)
    private let contextManager = ContextManager()
    private lazy var knowledgeEscort = KnowledgeEscort(
        knowledgeGraph: knowledgeGraph,
        vectorMemory: vectorMemory,
        contextManager: contextManager
    )
    
    // Planner with MLX
    private lazy var planner = AgentPlanner(mlxLLM: mlxLLM)
    
    // Workflow warmer (must be initialized before reasoning engine)
    private lazy var workflowWarmer = WorkflowWarmer(
        knowledgeEscort: knowledgeEscort,
        planner: planner,
        tools: tools
    )
    
    // Reasoning engine with MLX and workflow warmer
    private lazy var reasoningEngine = ReasoningEngine(
        planner: planner,
        knowledgeBase: knowledgeEscort,
        tools: tools,
        memory: memory,
        mlxLLM: mlxLLM,
        workflowWarmer: workflowWarmer
    )
    
    // Agent
    private lazy var agent = Agent(
        memory: memory,
        planner: planner,
        tools: tools,
        reasoningEngine: reasoningEngine,
        knowledgeEscort: knowledgeEscort
    )
    
    // Scheduling reasoner (handles all scheduling complexity)
    private lazy var calendarTool = CalendarTool()
    private lazy var tasksTool = TasksTool()
    private lazy var schedulingReasoner = SchedulingReasoner(
        reasoningEngine: reasoningEngine,
        mlxLLM: mlxLLM,
        calendarTool: calendarTool,
        tasksTool: tasksTool
    )
    
    // Proactive AI components
    private lazy var patternLearner = PatternLearner()
    private lazy var predictor = PredictiveEngine(patternLearner: patternLearner, workflowWarmer: workflowWarmer)
    private lazy var proactiveAssistant = ProactiveAssistant(
        knowledgeEscort: knowledgeEscort,
        memory: memory,
        patternLearner: patternLearner,
        predictor: predictor,
        workflowWarmer: workflowWarmer
    )
    
    init() {
        Task {
            // Load MLX models
            do {
                try await mlxLLM.load()
                try await mlxEmbeddings.load()
            } catch {
                print("MLX models not loaded, using fallback: \(error)")
            }
            
            // Register tools
            await tools.register(HTTPTool())
            await tools.register(FilesTool())
            await tools.register(calendarTool)
            await tools.register(ClipboardTool())
            await tools.register(tasksTool)
            
            // Connect workflow warmer to predictor
            await predictor.setWorkflowWarmer(workflowWarmer)
            
            // Load recent messages
            let recent = await memory.recent()
            await MainActor.run {
                self.messages = recent
            }
            
            // Load knowledge suggestions
            await loadSuggestions()
            
            // Load proactive suggestions and insights (this also warms workflows)
            await loadProactiveIntelligence()
        }
    }
    
    private func loadSuggestions() async {
        let context = ReasoningContext(
            entities: [],
            intent: .general,
            temporalContext: .now,
            userPreferences: UserPreferences()
        )
        let suggestions = await knowledgeEscort.suggest(context: context)
        await MainActor.run {
            self.knowledgeSuggestions = suggestions
        }
    }
    
    private func loadProactiveIntelligence() async {
        let context = ReasoningContext(
            entities: [],
            intent: .general,
            temporalContext: .now,
            userPreferences: UserPreferences()
        )
        
        // Load proactive suggestions
        let proactive = await proactiveAssistant.generateSuggestions(context: context)
        
        // Load insights
        let insights = await proactiveAssistant.generateInsights()
        
        // Load anticipated needs
        let needs = await proactiveAssistant.anticipateNeeds(context: context)
        
        await MainActor.run {
            self.proactiveSuggestions = Array(proactive.prefix(5)) // Top 5
            self.insights = Array(insights.prefix(3)) // Top 3
            self.anticipatedNeeds = Array(needs.prefix(3)) // Top 3
        }
    }
    
    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        isProcessing = true
        
        Task {
            do {
                // Check if this is a scheduling request
                let isSchedulingRequest = isSchedulingRelated(text)
                
                let context = ReasoningContext(
                    entities: [],
                    intent: .general,
                    temporalContext: .now,
                    userPreferences: UserPreferences()
                )
                
                if isSchedulingRequest {
                    // Use scheduling reasoner - handles all complexity automatically
                    let result = try await schedulingReasoner.schedule(text)
                    
                    // Learn from action
                    let action = UserAction(
                        type: .schedule,
                        entity: text,
                        timestamp: Date(),
                        context: context
                    )
                    await proactiveAssistant.learnFromAction(action: action, context: context)
                    
                    await MainActor.run {
                        self.messages.append(AgentMessage(
                            role: .assistant,
                            content: result.message,
                            timestamp: Date()
                        ))
                        self.isProcessing = false
                    }
                } else {
                    // Use general agent
                    let outputs = try await agent.handle(userInput: text)
                    
                    // Get reasoning trace from context manager
                    let currentContext = await contextManager.getCurrentContext()
                    
                    // Learn from action
                    let actionType: UserAction.ActionType = {
                        let lower = text.lowercased()
                        if lower.contains("create") || lower.contains("add") {
                            return .createTask
                        } else if lower.contains("complete") || lower.contains("done") {
                            return .completeTask
                        } else {
                            return .createTask
                        }
                    }()
                    let action = UserAction(
                        type: actionType,
                        entity: text,
                        timestamp: Date(),
                        context: context
                    )
                    await proactiveAssistant.learnFromAction(action: action, context: context)
                    
                    await MainActor.run {
                        self.messages.append(contentsOf: outputs)
                        self.reasoningTrace = currentContext?.reasoningTrace
                        self.isProcessing = false
                    }
                }
                
                // Reload suggestions and proactive intelligence
                await loadSuggestions()
                await loadProactiveIntelligence()
            } catch {
                await MainActor.run {
                    self.messages.append(AgentMessage(role: .assistant, content: "Error: \(error.localizedDescription)", timestamp: Date()))
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func isSchedulingRelated(_ text: String) -> Bool {
        let lower = text.lowercased()
        let schedulingKeywords = [
            "schedule", "meeting", "appointment", "event", "calendar",
            "task", "todo", "remind", "due", "deadline", "when",
            "tomorrow", "today", "friday", "monday", "next week",
            "at", "by", "before", "after", "during"
        ]
        return schedulingKeywords.contains { lower.contains($0) }
    }
    
    func askQuestion(_ question: String) async throws -> KnowledgeAnswer {
        return try await agent.answer(question)
    }
}

struct AgentConsoleView: View {
    @ObservedObject var viewModel: AgentConsoleViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Proactive suggestions bar
                if !viewModel.proactiveSuggestions.isEmpty {
                    proactiveSuggestionsBar
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        // Anticipated needs
                        if !viewModel.anticipatedNeeds.isEmpty {
                            Section("Anticipated Needs") {
                                ForEach(viewModel.anticipatedNeeds) { need in
                                    AnticipatedNeedRow(need: need, viewModel: viewModel)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Messages
                        ForEach(viewModel.messages) { msg in
                            MessageRow(message: msg)
                                .padding(.horizontal)
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    TextField("Ask or instruct the agent…", text: $viewModel.input)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isProcessing)
                    
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    
                    Button("Send") {
                        viewModel.send()
                    }
                    .disabled(viewModel.isProcessing || viewModel.input.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Agent Console")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingInsights.toggle() }) {
                        Image(systemName: "lightbulb")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingInsights) {
                InsightsView(insights: viewModel.insights)
            }
        }
    }
    
    private var proactiveSuggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.proactiveSuggestions) { suggestion in
                    ProactiveSuggestionChip(suggestion: suggestion, viewModel: viewModel)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct ProactiveSuggestionChip: View {
    let suggestion: ProactiveSuggestion
    @ObservedObject var viewModel: AgentConsoleViewModel
    
    var body: some View {
        Button(action: {
            viewModel.input = suggestion.action
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(suggestion.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

struct AnticipatedNeedRow: View {
    let need: AnticipatedNeed
    @ObservedObject var viewModel: AgentConsoleViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(need.description)
                    .font(.body)
                Text(need.reasoning)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                viewModel.input = need.suggestedAction
            }) {
                Text("Do it")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InsightsView: View {
    let insights: [Insight]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insight.title)
                            .font(.headline)
                        Text(insight.description)
                            .font(.body)
                        if let action = insight.suggestedAction {
                            Button(action: {}) {
                                Text(action)
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct MessageRow: View {
    let message: AgentMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(roleLabel(message.role))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(message.content)
                .font(.body)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(backgroundColor(for: message.role))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func roleLabel(_ role: AgentMessage.Role) -> String {
        switch role {
        case .user: return "You"
        case .assistant: return "Agent"
        case .system: return "System"
        case .tool: return "Tool"
        }
    }
    
    private func backgroundColor(for role: AgentMessage.Role) -> Color {
        switch role {
        case .user: return Color.blue.opacity(0.1)
        case .assistant: return Color.green.opacity(0.1)
        case .system: return Color.gray.opacity(0.1)
        case .tool: return Color.orange.opacity(0.1)
        }
    }
}
