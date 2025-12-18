// MLX-powered planner for intelligent scheduling and task planning
import Foundation

public actor AgentPlanner {
    private let mlxLLM: MLXLLM?
    
    public init(mlxLLM: MLXLLM? = nil) {
        self.mlxLLM = mlxLLM
    }
    
    public func plan(for userInput: String, availableTools: [AgentTool], knowledgeContext: [KnowledgeItem] = []) async -> AgentPlan {
        // Use MLX LLM if available
        if let mlx = mlxLLM {
            do {
                let context = SchedulingContext(
                    currentTime: Date(),
                    todayEvents: [],
                    tomorrowEvents: [],
                    upcomingEvents: [],
                    taskBacklog: [],
                    availableSlots: [],
                    userPreferences: UserSchedulingPreferences(
                        preferredWorkHours: (start: 9, end: 17),
                        bufferTime: 15 * 60,
                        autoSchedule: true
                    )
                )
                return try await mlx.generatePlan(
                    userInput: userInput,
                    availableTools: availableTools,
                    schedulingContext: context
                )
            } catch {
                // Fallback to heuristic
            }
        }
        
        // Heuristic fallback
        // Very simple heuristic planner to start; replace with MLX LLM-driven planner
        // Detect URLs, file paths, or keywords to pick tools
        let lower = userInput.lowercased()
        var steps: [AgentPlanStep] = []
        
        if lower.contains("fetch") || lower.contains("http") || lower.contains("api") {
            if availableTools.contains(where: { $0.name == "http" }) {
                steps.append(AgentPlanStep(description: "Fetch HTTP resource", toolName: "http", arguments: ["url": userInput]))
            }
        }
        if lower.contains("save") || lower.contains("write") || lower.contains("file") {
            if availableTools.contains(where: { $0.name == "files" }) {
                steps.append(AgentPlanStep(description: "Write to local file", toolName: "files", arguments: ["path": "Documents/agent_output.txt", "content": userInput]))
            }
        }
        if lower.contains("task") || lower.contains("todo") {
            if availableTools.contains(where: { $0.name == "tasks" }) {
                steps.append(AgentPlanStep(description: "Create or manage task", toolName: "tasks", arguments: ["action": "create", "title": userInput]))
            }
        }
        if lower.contains("calendar") || lower.contains("event") || lower.contains("schedule") {
            if availableTools.contains(where: { $0.name == "calendar" }) {
                steps.append(AgentPlanStep(description: "Manage calendar event", toolName: "calendar", arguments: ["action": "create", "title": userInput]))
            }
        }
        if steps.isEmpty {
            // Default: echo assistant
            steps.append(AgentPlanStep(description: "Respond to user", toolName: nil, arguments: [:]))
        }
        return AgentPlan(steps: steps)
    }
}
