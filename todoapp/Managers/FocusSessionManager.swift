import SwiftUI
import EventKit

@Observable
final class FocusSessionManager {
    enum Phase { case idle, setup, active }

    var phase: Phase = .setup
    var selectedTasks: [EKReminder] = []
    var showCalendar = false
    var duration: TimeInterval = 25 * 60
    var currentIndex = 0
    var sessionComplete = false

    var currentTask: EKReminder? {
        guard currentIndex < selectedTasks.count else { return nil }
        return selectedTasks[currentIndex]
    }

    var upcomingTasks: [EKReminder] {
        guard currentIndex < selectedTasks.count else { return [] }
        return Array(selectedTasks[(currentIndex + 1)...])
    }

    var completedTasks: [EKReminder] {
        Array(selectedTasks[..<currentIndex])
    }

    func moveNext() {
        if currentIndex < selectedTasks.count {
            currentIndex += 1
        }
        if currentIndex >= selectedTasks.count {
            sessionComplete = true
        }
    }

    func reset() {
        phase = .setup
        selectedTasks = []
        showCalendar = false
        duration = 25 * 60
        currentIndex = 0
        sessionComplete = false
    }
}
