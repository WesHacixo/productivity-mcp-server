// Tasks list view
import SwiftUI

struct TasksView: View {
    @State private var tasks: [TaskItem] = []
    @State private var filter: TaskFilter = .all
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case overdue = "Overdue"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter segmented control
                Picker("Filter", selection: $filter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Tasks list
                List {
                    ForEach(filteredTasks) { task in
                        TaskRow(task: task)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadTasks()
            }
        }
    }
    
    private var filteredTasks: [TaskItem] {
        let now = Date()
        switch filter {
        case .all:
            return tasks
        case .today:
            return tasks.filter { Calendar.current.isDateInToday($0.dueDate ?? now) }
        case .overdue:
            return tasks.filter { ($0.dueDate ?? now) < now && !$0.completed }
        case .completed:
            return tasks.filter { $0.completed }
        }
    }
    
    private func loadTasks() {
        // TODO: Load from MCP server
        tasks = [
            TaskItem(id: UUID(), title: "Finish report", completed: false, dueDate: Date().addingTimeInterval(3600)),
            TaskItem(id: UUID(), title: "Review code", completed: false, dueDate: Date().addingTimeInterval(7200))
        ]
    }
}

struct TaskItem: Identifiable {
    let id: UUID
    let title: String
    var completed: Bool
    let dueDate: Date?
}

struct TaskRow: View {
    @State var task: TaskItem
    
    var body: some View {
        HStack {
            Button(action: {
                task.completed.toggle()
            }) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.completed ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.completed)
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}
