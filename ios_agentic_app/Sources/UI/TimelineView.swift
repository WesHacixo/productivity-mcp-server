// Unified timeline view combining calendar, tasks, and goals (Structured-style)
import SwiftUI

struct TimelineView: View {
    @State private var selectedDate = Date()
    @State private var events: [TimelineEvent] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date selector
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)
                    
                    // Timeline
                    ForEach(events) { event in
                        TimelineEventRow(event: event)
                    }
                }
                .padding()
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadEvents()
            }
        }
    }
    
    private func loadEvents() {
        // TODO: Load from local storage and MCP server
        events = [
            TimelineEvent(id: UUID(), type: .task, title: "Finish report", time: Date().addingTimeInterval(3600)),
            TimelineEvent(id: UUID(), type: .calendar, title: "Team meeting", time: Date().addingTimeInterval(7200)),
            TimelineEvent(id: UUID(), type: .goal, title: "Complete milestone", time: Date().addingTimeInterval(10800))
        ]
    }
}

struct TimelineEvent: Identifiable {
    let id: UUID
    let type: EventType
    let title: String
    let time: Date
    
    enum EventType {
        case task
        case calendar
        case goal
        case habit
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time indicator
            VStack {
                Circle()
                    .fill(colorForType(event.type))
                    .frame(width: 12, height: 12)
                if event.type != .task {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            
            // Event content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                Text(event.time, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func colorForType(_ type: TimelineEvent.EventType) -> Color {
        switch type {
        case .task: return .blue
        case .calendar: return .green
        case .goal: return .purple
        case .habit: return .orange
        }
    }
}
