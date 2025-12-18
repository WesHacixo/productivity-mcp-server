// Clipboard tool for reading/writing clipboard
import Foundation
#if canImport(UIKit)
import UIKit
#endif

public struct ClipboardTool: AgentTool {
    public let name = "clipboard"
    public let description = "Read from or write to the system clipboard"
    public let inputSchema: [String: String] = [
        "action": "string (read|write)",
        "text": "string (required for write)"
    ]
    
    public init() {}
    
    public func call(args: [String: String], policy: ToolPolicy) async throws -> String {
        let action = args["action"] ?? "read"
        
        switch action {
        case "read":
            return await readClipboard()
        case "write":
            guard let text = args["text"] else {
                throw AgentError.toolExecution("Missing 'text' for write action")
            }
            return await writeClipboard(text: text)
        default:
            throw AgentError.toolExecution("Unknown action: \(action)")
        }
    }
    
    private func readClipboard() async -> String {
        #if canImport(UIKit)
        await MainActor.run {
            UIPasteboard.general.string ?? ""
        }
        #else
        return "Clipboard not available on this platform"
        #endif
    }
    
    private func writeClipboard(text: String) async -> String {
        #if canImport(UIKit)
        await MainActor.run {
            UIPasteboard.general.string = text
            return "Wrote \(text.count) characters to clipboard"
        }
        #else
        return "Clipboard not available on this platform"
        #endif
    }
}
