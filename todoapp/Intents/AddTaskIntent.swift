import AppIntents
import EventKit
import WidgetKit

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Добавить задачу"
    static var description: LocalizedStringResource = "Добавляет задачу в ваш список напоминаний"

    @Parameter(title: "Задача")
    var task: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard !task.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw IntentError("Текст задачи не может быть пустым")
        }

        let store = EKEventStore()
        do {
            try await store.requestFullAccessToReminders()
        } catch {
            throw IntentError("Нет доступа к напоминаниям. Разрешите доступ в настройках.")
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = task
        reminder.calendar = store.defaultCalendarForNewReminders()
            ?? store.calendars(for: .reminder).first

        try store.save(reminder, commit: true)
        WidgetCenter.shared.reloadTimelines(ofKind: "TodoWidgetsExtension")

        return .result(dialog: "✅ «\(task)» добавлена")
    }
}

struct IntentError: Error, CustomLocalizedStringResourceConvertible {
    var message: String

    init(_ message: String) {
        self.message = message
    }

    var localizedStringResource: LocalizedStringResource {
        .init(stringLiteral: message)
    }
}
