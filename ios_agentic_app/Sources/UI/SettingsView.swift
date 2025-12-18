// Settings view
import SwiftUI

struct SettingsView: View {
    @AppStorage("mcpServerURL") private var mcpServerURL = "https://productivity-mcp-server-production.up.railway.app"
    @AppStorage("allowNetwork") private var allowNetwork = true
    @AppStorage("allowFileIO") private var allowFileIO = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("MCP Server") {
                    TextField("Server URL", text: $mcpServerURL)
                }
                
                Section("Agent Policy") {
                    Toggle("Allow Network", isOn: $allowNetwork)
                    Toggle("Allow File IO", isOn: $allowFileIO)
                }
                
                Section("About") {
                    Text("Productivity Agentic App")
                    Text("Version 1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
