// Main content view with tab navigation
import SwiftUI

struct ContentView: View {
    @StateObject private var agentViewModel = AgentConsoleViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
                .tag(0)
            
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(1)
            
            AgentConsoleView(viewModel: agentViewModel)
                .tabItem {
                    Label("Agent", systemImage: "brain")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}
