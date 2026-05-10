import WidgetKit
import SwiftUI
import EventKit
import AppIntents

struct TasksEntry: TimelineEntry {
    let date: Date
    let tasks: [EKReminder]
    let error: String?
}

struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Выполнить задачу"

    @Parameter(title: "ID задачи")
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
            completion(Timeline(entries: [entry], policy: .never))
        }
    }

    func entry() async -> TasksEntry {
        let store = EKEventStore()
        do {
            try await store.requestFullAccessToReminders()
        } catch {
            return TasksEntry(date: Date(), tasks: [], error: "Нет доступа")
        }

        let lists = store.calendars(for: .reminder)
        guard !lists.isEmpty else {
            return TasksEntry(date: Date(), tasks: [], error: "Нет списков")
        }

        let predicate = store.predicateForReminders(in: nil)
        let all = await withCheckedContinuation { cont in
            store.fetchReminders(matching: predicate) { all in
                cont.resume(returning: all ?? [])
            }
        }

        let pending = all.filter { !$0.isCompleted }.prefix(6)
        return TasksEntry(date: Date(), tasks: Array(pending), error: nil)
    }
}

struct TodoWidgetsExtensionEntryView: View {
    var entry: TasksEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "checklist")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("Задачи")
                    .font(.caption.bold())
                Spacer()
            }

            if let error = entry.error {
                Spacer()
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if entry.tasks.isEmpty {
                Spacer()
                Text("Нет задач 🎉")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.tasks, id: \.calendarItemIdentifier) { task in
                    Button(intent: CompleteTaskIntent(taskID: task.calendarItemIdentifier)) {
                        HStack(spacing: 6) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(task.title ?? "")
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct TodoWidgetsExtension: Widget {
    let kind: String = "TodoWidgetsExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetsExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Продуктив")
        .description("Невыполненные задачи из всех списков")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
