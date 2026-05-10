import EventKit
import SwiftUI
import WidgetKit

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
        if calendarGranted { fetchEventsAround(Date()) }
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
            fetchEventsAround(Date())
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
        store.fetchReminders(matching: store.predicateForReminders(in: nil)) { [weak self] all in
            guard let self else { return }
            if all == nil {
                DispatchQueue.main.async {
                    self.remindersError = true
                    self._store = nil
                }
                return
            }
            let sorted = all!.sorted { ($0.dueDateComponents?.date ?? .distantFuture) < ($1.dueDateComponents?.date ?? .distantFuture) }
            DispatchQueue.main.async {
                self.reminders = sorted
                self.remindersError = false
            }
        }
    }

    func addReminder(title: String, list: EKCalendar? = nil) {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = list ?? selectedList ?? store.defaultCalendarForNewReminders()
        try? store.save(reminder, commit: true)
        fetchReminders()
        WidgetCenter.shared.reloadTimelines(ofKind: "TodoWidgetsExtension")
    }

    func toggleComplete(_ reminder: EKReminder) {
        reminder.isCompleted = !reminder.isCompleted
        try? store.save(reminder, commit: true)
        fetchReminders()
        WidgetCenter.shared.reloadTimelines(ofKind: "TodoWidgetsExtension")
    }

    var calendarEventLists: [EKCalendar] {
        store.calendars(for: .event)
    }

    func fetchEvents(from start: Date, to end: Date) {
        let all = store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: nil))
        events = all.sorted { $0.startDate < $1.startDate }
    }

    func createEvent(title: String, location: String? = nil, startDate: Date, endDate: Date, notes: String? = nil, calendar: EKCalendar? = nil, isAllDay: Bool = false) {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.location = location
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.isAllDay = isAllDay
        event.calendar = calendar ?? store.defaultCalendarForNewEvents ?? store.calendars(for: .event).first
        try? store.save(event, span: .thisEvent, commit: true)
    }

    func fetchEventsAround(_ date: Date) {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? date
        fetchEvents(from: start, to: end)
    }
}
