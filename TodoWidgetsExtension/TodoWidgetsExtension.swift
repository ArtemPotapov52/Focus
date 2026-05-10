import WidgetKit
import SwiftUI
import EventKit
import AppIntents

// MARK: - EKEvent Identifiable

extension EKEvent: @retroactive Identifiable {
    public var id: String { eventIdentifier }
}

// MARK: - Entry

struct TasksEntry: TimelineEntry {
    let date: Date
    let tasks: [EKReminder]
    let events: [EKEvent]
    let error: String?
}

// MARK: - Complete Task Intent

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"

    @Parameter(title: "Task ID")
    var taskID: String

    init(taskID: String) { self.taskID = taskID }
    init() {}

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let store = EKEventStore()
        let predicate = store.predicateForReminders(in: nil)
        let reminders = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[EKReminder], Error>) in
            store.fetchReminders(matching: predicate) { all in
                if let all { cont.resume(returning: all) }
                else { cont.resume(throwing: NSError(domain: "EK", code: -1)) }
            }
        }
        if let task = reminders.first(where: { $0.calendarItemIdentifier == taskID }) {
            task.isCompleted = true
            try store.save(task, commit: true)
        }
        return .result()
    }
}

// MARK: - Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry(date: Date(), tasks: [], events: [], error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> Void) {
        Task { completion(await entry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> Void) {
        Task {
            let entry = await entry()
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    func entry() async -> TasksEntry {
        let store = EKEventStore()

        // Reminders
        var tasks: [EKReminder] = []
        do {
            try await store.requestFullAccessToReminders()
            let lists = store.calendars(for: .reminder)
            if !lists.isEmpty {
                let predicate = store.predicateForReminders(in: nil)
                let all = await withCheckedContinuation { cont in
                    store.fetchReminders(matching: predicate) { all in
                        cont.resume(returning: all ?? [])
                    }
                }
                tasks = Array(all.filter { !$0.isCompleted }.prefix(7))
            }
        } catch {
            return TasksEntry(date: Date(), tasks: [], events: [], error: "No reminders access")
        }

        // Calendar events for today
        var events: [EKEvent] = []
        do {
            try await store.requestFullAccessToEvents()
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
            let predicate = store.predicateForEvents(withStart: today, end: tomorrow, calendars: nil)
            events = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        } catch {}

        return TasksEntry(date: Date(), tasks: tasks, events: events, error: nil)
    }
}

// MARK: - Color hex helper (inline for widget)

private func hexColor(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    guard let val = UInt64(hex, radix: 16) else { return .black }
    let r = Double((val >> 16) & 0xFF) / 255
    let g = Double((val >> 8) & 0xFF) / 255
    let b = Double(val & 0xFF) / 255
    return Color(red: r, green: g, blue: b)
}

private func timeString(_ date: Date) -> String {
    let df = DateFormatter()
    df.dateFormat = "HH:mm"
    return df.string(from: date)
}

// MARK: - Widget View

struct TodoWidgetsExtensionEntryView: View {
    var entry: TasksEntry
    @Environment(\.widgetFamily) var family

    private let textPrimary = Color(red: 0.1, green: 0.11, blue: 0.11) // #1a1c1c
    private let textSecondary = Color(red: 0.267, green: 0.278, blue: 0.282).opacity(0.6) // #444748

    var body: some View {
        VStack(spacing: 0) {
            if let error = entry.error {
                Spacer()
                Text(error)
                    .font(.caption)
                    .foregroundColor(textSecondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                // Events row
                if !entry.events.isEmpty {
                    eventsRow
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                }

                // Tasks
                tasksList
                    .padding(.horizontal, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .containerBackground(.white, for: .widget)
    }

    // MARK: - Events Row

    private var eventsRow: some View {
        HStack(spacing: 6) {
            ForEach(entry.events.prefix(4), id: \.eventIdentifier) { event in
                eventChip(event)
            }
            if entry.events.count > 4 {
                Text("+\(entry.events.count - 4)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eventChip(_ event: EKEvent) -> some View {
        let now = Date()
        let bg: Color
        if event.endDate < now { bg = hexColor("f0f7f0") }
        else if event.startDate <= now && event.endDate >= now { bg = hexColor("eef6ff") }
        else { bg = hexColor("fff5f5") }

        return HStack(spacing: 4) {
            Text(timeString(event.startDate))
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(textSecondary)
            Text(event.title ?? "")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Tasks List

    private var tasksList: some View {
        let maxTasks: Int
        if family == .systemLarge {
            maxTasks = 7
        } else if family == .systemMedium {
            maxTasks = 4
        } else {
            maxTasks = 3
        }

        let shown = Array(entry.tasks.prefix(maxTasks))

        return VStack(spacing: 0) {
            if shown.isEmpty {
                Spacer(minLength: 0)
                Text("No tasks")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(textSecondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            } else {
                ForEach(shown, id: \.calendarItemIdentifier) { task in
                    Button(intent: CompleteTaskIntent(taskID: task.calendarItemIdentifier)) {
                        HStack(spacing: 8) {
                            Circle()
                                .stroke(textSecondary.opacity(0.5), lineWidth: 1.5)
                                .frame(width: 16, height: 16)

                            Text(task.title ?? "")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(textPrimary)
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    if task != shown.last {
                        Divider()
                            .background(textPrimary.opacity(0.06))
                            .padding(.leading, 24)
                    }
                }
            }
        }
    }
}

// MARK: - Widget Configuration

struct TodoWidgetsExtension: Widget {
    let kind: String = "TodoWidgetsExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetsExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Focus")
        .description("Today's events and tasks")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
