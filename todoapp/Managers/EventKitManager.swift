import EventKit
import SwiftUI

@Observable
final class EventKitManager {
    private var _store: EKEventStore?
    var store: EKEventStore {
        if let s = _store { return s }
        let s = EKEventStore()
        _store = s
        return s
    }

    var remindersGranted = false
    var calendarGranted = false
    var reminderLists: [EKCalendar] = []
    var reminders: [EKReminder] = []
    var events: [EKEvent] = []
    var remindersError = false
    var isLoading = false

    private var selectedCalendarID: String?

    var selectedList: EKCalendar? {
        didSet {
            selectedCalendarID = selectedList?.calendarIdentifier
            fetchReminders()
        }
    }

    func requestAccess() async {
        do {
            try await store.requestFullAccessToReminders()
            remindersGranted = true
        } catch {
            remindersGranted = false
        }
        do {
            try await store.requestFullAccessToEvents()
            calendarGranted = true
        } catch {
            calendarGranted = false
        }
        if remindersGranted { fetchLists() }
        if calendarGranted { fetchEvents() }
    }

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        remindersError = false
        if remindersGranted {
            fetchLists()
            fetchReminders()
        }
        if calendarGranted {
            fetchEvents()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
        }
    }

    func fetchLists() {
        reminderLists = store.calendars(for: .reminder)
        if let id = selectedCalendarID,
           let saved = reminderLists.first(where: { $0.calendarIdentifier == id })
        {
            selectedList = saved
        } else {
            selectedList = reminderLists.first
        }
    }

    func fetchReminders() {
        guard let list = selectedList else { return }
        store.fetchReminders(matching: store.predicateForReminders(in: [list])) { [weak self] all in
            guard let self else { return }
            if all == nil {
                DispatchQueue.main.async {
                    self.remindersError = true
                    self._store = nil
                }
                return
            }
            let sorted = all!.filter { !$0.isCompleted }.sorted { ($0.dueDateComponents?.date ?? .distantFuture) < ($1.dueDateComponents?.date ?? .distantFuture) }
            DispatchQueue.main.async {
                self.reminders = sorted
                self.remindersError = false
            }
        }
    }

    func toggleComplete(_ reminder: EKReminder) {
        reminder.isCompleted = !reminder.isCompleted
        try? store.save(reminder, commit: true)
        fetchReminders()
    }

    func fetchEvents() {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let all = store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: nil))
        events = all.sorted { $0.startDate < $1.startDate }
    }
}
