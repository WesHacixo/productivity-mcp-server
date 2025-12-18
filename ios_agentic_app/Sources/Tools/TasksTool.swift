// Tasks tool for managing productivity tasks via MCP server
import Foundation

public struct TasksTool: AgentTool {
    public let name = "tasks"
    public let description = "Create, list, or manage tasks via the MCP server"
    public let inputSchema: [String: String] = [
        "action": "string (create|list|update|delete)",
        "title": "string",
        "description": "string",
        "dueDate": "string (ISO8601)",
        "priority": "string (1-4)",
        "taskId": "string (for update/delete)"
    ]
    
    private let mcpServerURL: String
    
    public init(mcpServerURL: String = "https://productivity-mcp-server-production.up.railway.app") {
        self.mcpServerURL = mcpServerURL
    }
    
    public func call(args: [String: String], policy: ToolPolicy) async throws -> String {
        guard policy.allowNetwork else {
            throw AgentError.toolExecution("Network disabled by policy")
        }
        
        let action = args["action"] ?? "list"
        
        switch action {
        case "create":
            return try await createTask(args: args)
        case "list":
            return try await listTasks()
        case "update":
            return try await updateTask(args: args)
        case "delete":
            return try await deleteTask(args: args)
        default:
            throw AgentError.toolExecution("Unknown action: \(action)")
        }
    }
    
    private func createTask(args: [String: String]) async throws -> String {
        guard let title = args["title"] else {
            throw AgentError.toolExecution("Missing 'title'")
        }
        
        var taskData: [String: Any] = ["title": title]
        if let description = args["description"] {
            taskData["description"] = description
        }
        if let dueDate = args["dueDate"] {
            taskData["due_date"] = dueDate
        }
        if let priority = args["priority"] {
            taskData["priority"] = Int(priority) ?? 3
        }
        
        let url = URL(string: "\(mcpServerURL)/api/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: taskData)
        
        // TODO: Add authentication token
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AgentError.toolExecution("Failed to create task")
        }
        
        return "Created task: \(title)"
    }
    
    private func listTasks() async throws -> String {
        let url = URL(string: "\(mcpServerURL)/api/tasks")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // TODO: Add authentication token
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AgentError.toolExecution("Failed to list tasks")
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let taskList = json.prefix(10).compactMap { task in
                task["title"] as? String
            }.joined(separator: "\n")
            return "Tasks:\n\(taskList.isEmpty ? "No tasks" : taskList)"
        }
        
        return "No tasks found"
    }
    
    private func updateTask(args: [String: String]) async throws -> String {
        // Implementation for updating tasks
        return "Update not yet implemented"
    }
    
    private func deleteTask(args: [String: String]) async throws -> String {
        // Implementation for deleting tasks
        return "Delete not yet implemented"
    }
}
