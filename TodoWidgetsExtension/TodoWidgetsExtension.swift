import WidgetKit
import SwiftUI
import EventKit
import AppIntents

// MARK: - Entity (Reminder List)

struct ReminderListEntity: AppEntity {
    let id: String
    let title: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Список"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    static var defaultQuery = ReminderListQuery()
}

// MARK: - Query

struct ReminderListQuery: EntityQuery {
    func entities(for identifiers: [ReminderListEntity.ID]) async throws -> [ReminderListEntity] {
        let store = EKEventStore()
        let lists = store.calendars(for: .reminder)
        return lists
            .filter { identifiers.contains($0.calendarIdentifier) }
            .map { ReminderListEntity(id: $0.calendarIdentifier, title: $0.title) }
    }

    func suggestedEntities() async throws -> [ReminderListEntity] {
        let store = EKEventStore()
        let lists = store.calendars(for: .reminder)
        return lists.map { ReminderListEntity(id: $0.calendarIdentifier, title: $0.title) }
    }
}

// MARK: - Configuration Intent

struct SelectListIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Выбрать список"
    static var description: LocalizedStringResource = "Выберите список напоминаний для отображения"

    @Parameter(title: "Список")
    var list: ReminderListEntity?
}

// MARK: - Entry

struct TasksEntry: TimelineEntry {
    let date: Date
    let tasks: [EKReminder]
    let error: String?
    let listTitle: String?
}

// MARK: - Interactive Intent

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

// MARK: - Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry(date: Date(), tasks: [], error: nil, listTitle: nil)
    }

    func snapshot(for configuration: SelectListIntent, in context: Context) async -> TasksEntry {
        await entry(for: configuration)
    }

    func timeline(for configuration: SelectListIntent, in context: Context) async -> Timeline<TasksEntry> {
        let entry = await entry(for: configuration)
        return Timeline(entries: [entry], policy: .never)
    }

    func entry(for configuration: SelectListIntent) async -> TasksEntry {
        let store = EKEventStore()
        do {
            try await store.requestFullAccessToReminders()
        } catch {
            return TasksEntry(date: Date(), tasks: [], error: "Нет доступа", listTitle: nil)
        }

        let selectedID = configuration.list?.id
        let lists: [EKCalendar]

        if let selectedID {
            let filtered = store.calendars(for: .reminder).filter { $0.calendarIdentifier == selectedID }
            lists = filtered
        } else {
            lists = store.calendars(for: .reminder)
        }

        guard !lists.isEmpty else {
            return TasksEntry(date: Date(), tasks: [], error: "Нет списков", listTitle: nil)
        }

        let predicate = store.predicateForReminders(in: lists.isEmpty ? nil : lists)
        let all = await withCheckedContinuation { cont in
            store.fetchReminders(matching: predicate) { all in
                cont.resume(returning: all ?? [])
            }
        }

        let pending = all.filter { !$0.isCompleted }.prefix(6)
        return TasksEntry(
            date: Date(),
            tasks: Array(pending),
            error: nil,
            listTitle: configuration.list?.title
        )
    }
}

// MARK: - View

struct TodoWidgetsExtensionEntryView: View {
    var entry: TasksEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "checklist")
                    .font(.caption)
                    .foregroundColor(.green)
                Text(entry.listTitle ?? "Задачи")
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

// MARK: - Widget

struct TodoWidgetsExtension: Widget {
    let kind: String = "TodoWidgetsExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectListIntent.self, provider: Provider()) { entry in
            TodoWidgetsExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Продуктив")
        .description("Невыполненные задачи. Нажмите для настройки списка.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
