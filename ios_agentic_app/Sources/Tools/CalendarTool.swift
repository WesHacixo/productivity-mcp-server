// Calendar tool for managing events
import Foundation
import EventKit

public struct CalendarTool: AgentTool {
    public let name = "calendar"
    public let description = "Create, read, or manage calendar events"
    public let inputSchema: [String: String] = [
        "action": "string (create|list|delete)",
        "title": "string",
        "startDate": "string (ISO8601)",
        "endDate": "string (ISO8601)",
        "notes": "string"
    ]
    
    private let eventStore = EKEventStore()
    
    public init() {}
    
    public func call(args: [String: String], policy: ToolPolicy) async throws -> String {
        let action = args["action"] ?? "list"
        
        // Request calendar access
        let status = await eventStore.requestAccess(to: .event)
        guard status else {
            throw AgentError.toolExecution("Calendar access denied")
        }
        
        switch action {
        case "create":
            return try await createEvent(args: args)
        case "list":
            return try await listEvents()
        case "delete":
            return try await deleteEvent(args: args)
        default:
            throw AgentError.toolExecution("Unknown action: \(action)")
        }
    }
    
    private func createEvent(args: [String: String]) throws -> String {
        guard let title = args["title"] else {
            throw AgentError.toolExecution("Missing 'title'")
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.notes = args["notes"]
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        if let startStr = args["startDate"],
           let startDate = ISO8601DateFormatter().date(from: startStr) {
            event.startDate = startDate
            if let endStr = args["endDate"],
               let endDate = ISO8601DateFormatter().date(from: endStr) {
                event.endDate = endDate
            } else {
                event.endDate = startDate.addingTimeInterval(3600) // Default 1 hour
            }
        } else {
            // Default to today, 1 hour from now
            event.startDate = Date()
            event.endDate = Date().addingTimeInterval(3600)
        }
        
        try eventStore.save(event, span: .thisEvent)
        return "Created calendar event: \(title)"
    }
    
    private func listEvents() throws -> String {
        let calendars = eventStore.calendars(for: .event)
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400 * 7) // Next 7 days
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        let eventList = events.prefix(10).map { event in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "\(formatter.string(from: event.startDate)) - \(event.title ?? "Untitled")"
        }.joined(separator: "\n")
        
        return "Upcoming events:\n\(eventList)"
    }
    
    private func deleteEvent(args: [String: String]) throws -> String {
        // Implementation would find and delete event by title/date
        return "Delete not yet implemented"
    }
}
