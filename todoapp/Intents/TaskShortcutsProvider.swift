import AppIntents

struct TaskShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Добавить задачу в \(.applicationName)",
                "Создать задачу в \(.applicationName)",
                "Быстрая задача в \(.applicationName)",
            ],
            shortTitle: "Быстрая задача",
            systemImageName: "plus.circle"
        )
    }
}
