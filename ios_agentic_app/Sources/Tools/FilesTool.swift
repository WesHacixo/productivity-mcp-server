// Local file tool restricted to allowed paths
import Foundation

public struct FilesTool: AgentTool {
    public let name = "files"
    public let description = "Write text content to a file in allowed paths"
    public let inputSchema: [String: String] = ["path": "string", "content": "string"]
    
    public init() {}
    
    public func call(args: [String: String], policy: ToolPolicy) async throws -> String {
        guard policy.allowFileIO else {
            throw AgentError.toolExecution("File IO disabled by policy")
        }
        guard let relPath = args["path"], let content = args["content"] else {
            throw AgentError.toolExecution("Missing 'path' or 'content'")
        }
        
        // Only allow writes within allowed paths in the app sandbox
        let baseDirs = policy.allowedPaths
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let candidates: [String: URL] = ["Documents": documents, "Library": library]
        
        guard let firstPrefix = baseDirs.first(where: { relPath.hasPrefix($0) }),
              let baseURL = candidates[firstPrefix] else {
            throw AgentError.toolExecution("Path not allowed")
        }
        
        let relative = relPath.replacingOccurrences(of: "\(firstPrefix)/", with: "")
        let fileURL = baseURL.appendingPathComponent(relative)
        try content.data(using: .utf8)?.write(to: fileURL, options: [.atomic])
        return "Wrote \(content.count) chars to \(firstPrefix)/\(relative)"
    }
}
