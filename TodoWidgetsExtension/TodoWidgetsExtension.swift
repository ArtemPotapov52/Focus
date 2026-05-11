import WidgetKit
import SwiftUI
import EventKit
import AppIntents

struct TasksEntry: TimelineEntry {
    let date: Date
    let tasks: [EKReminder]
    let error: String?
}

// MARK: - Complete Task Intent

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var isDiscoverable = false

    @Parameter(title: "Task ID")
    var taskID: String
    @Parameter(title: "Task Title")
    var taskTitle: String?

    init(taskID: String, taskTitle: String? = nil) {
        self.taskID = taskID
        self.taskTitle = taskTitle
    }
    init() {}

    func perform() async throws -> some IntentResult {
        let store = EKEventStore()
        try await store.requestFullAccessToReminders()
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
        TasksEntry(date: Date(), tasks: [], error: nil)
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
        var tasks: [EKReminder] = []
        do {
            try await store.requestFullAccessToReminders()
            if !store.calendars(for: .reminder).isEmpty {
                let predicate = store.predicateForReminders(in: nil)
                let all = await withCheckedContinuation { cont in
                    store.fetchReminders(matching: predicate) { all in
                        cont.resume(returning: all ?? [])
                    }
                }
                tasks = Array(all.filter { !$0.isCompleted })
                    .sorted { a, b in
                        let order: [Int: Int] = [1: 0, 5: 1, 9: 2, 0: 3]
                        return (order[a.priority] ?? 3) < (order[b.priority] ?? 3)
                    }
            }
        } catch {
            return TasksEntry(date: Date(), tasks: [], error: "No access")
        }
        return TasksEntry(date: Date(), tasks: tasks, error: nil)
    }
}

// MARK: - Entry View

struct TodoWidgetsExtensionEntryView: View {
    var entry: TasksEntry

    var body: some View {
        VStack(spacing: 0) {
            if let error = entry.error {
                Spacer()
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                tasksList
                    .padding(.horizontal, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .containerBackground(.background, for: .widget)
    }

    private var tasksList: some View {
        let shown = entry.tasks

        return VStack(spacing: 0) {
            if shown.isEmpty {
                Spacer(minLength: 0)
                Text("No tasks")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            } else {
                ForEach(Array(shown.enumerated()), id: \.element.calendarItemIdentifier) { index, task in
                    Button(intent: CompleteTaskIntent(
                        taskID: task.calendarItemIdentifier,
                        taskTitle: task.title
                    )) {
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(priorityColor(task.priority))
                                .frame(width: 3)
                                .padding(.vertical, 2)

                            Circle()
                                .stroke(.primary, lineWidth: 2)
                                .frame(width: 16, height: 16)

                            Text(task.title ?? "")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func priorityColor(_ p: Int) -> Color {
        switch p {
        case 1: return .red
        case 5: return .blue
        case 9: return .green
        default: return .clear
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
        .configurationDisplayName("Tasks")
        .description("Upcoming tasks")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
