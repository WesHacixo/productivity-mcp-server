// SwiftUI console for interacting with the agent
import SwiftUI

final class AgentConsoleViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var messages: [AgentMessage] = []
    @Published var isProcessing: Bool = false
    @Published var reasoningTrace: ReasoningTrace?
    @Published var knowledgeSuggestions: [Suggestion] = []
    
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
    
    // Reasoning engine with MLX
    private lazy var reasoningEngine = ReasoningEngine(
        planner: planner,
        knowledgeBase: knowledgeEscort,
        tools: tools,
        memory: memory,
        mlxLLM: mlxLLM
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
            
            // Load recent messages
            let recent = await memory.recent()
            await MainActor.run {
                self.messages = recent
            }
            
            // Load knowledge suggestions
            await loadSuggestions()
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
    
    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        isProcessing = true
        
        Task {
            do {
                // Check if this is a scheduling request
                let isSchedulingRequest = isSchedulingRelated(text)
                
                if isSchedulingRequest {
                    // Use scheduling reasoner - handles all complexity automatically
                    let result = try await schedulingReasoner.schedule(text)
                    
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
                    
                    await MainActor.run {
                        self.messages.append(contentsOf: outputs)
                        self.reasoningTrace = currentContext?.reasoningTrace
                        self.isProcessing = false
                    }
                }
                
                // Reload suggestions after new knowledge integration
                await loadSuggestions()
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
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
