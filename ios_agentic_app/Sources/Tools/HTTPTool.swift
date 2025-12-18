// Safe HTTP fetch tool with domain allowlist
import Foundation

public struct HTTPTool: AgentTool {
    public let name = "http"
    public let description = "Perform a GET request to an allowed domain"
    public let inputSchema: [String: String] = ["url": "string"]
    
    public init() {}
    
    public func call(args: [String: String], policy: ToolPolicy) async throws -> String {
        guard policy.allowNetwork else {
            throw AgentError.toolExecution("Network disabled by policy")
        }
        guard let raw = args["url"], let url = URL(string: raw) else {
            throw AgentError.toolExecution("Missing or invalid 'url'")
        }
        guard let host = url.host, policy.allowedDomains.contains(host) else {
            throw AgentError.toolExecution("Domain '\(url.host ?? "?")' not allowed")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AgentError.toolExecution("HTTP error")
        }
        
        if data.count > policy.maxResponseBytes {
            throw AgentError.toolExecution("Response too large")
        }
        
        // Return first 4k characters to keep UI snappy
        let text = String(data: data, encoding: .utf8) ?? "<binary \(data.count) bytes>"
        return String(text.prefix(4096))
    }
}
