import SwiftUI
import EventKit

extension EKEvent: @retroactive Identifiable {
    public var id: String { eventIdentifier }
}

struct CalendarView: View {
    @Bindable var ek: EventKitManager
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()
    @State private var showAddEvent = false
    @State private var selectedEvent: EKEvent?
    @Namespace private var selectionAnimation

    private let cal = Calendar.current
    private var weekdays: [String] {
        let sym = cal.shortStandaloneWeekdaySymbols
        let s = cal.firstWeekday - 1
        return (Array(sym[s...]) + Array(sym[..<s])).map { String($0.prefix(1)) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBg.ignoresSafeArea()

            if !ek.calendarGranted {
                noAccessView
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        scheduleHeader
                        weekdayRow
                        monthGrid
                        dailyAgenda
                    }
                    .padding(.bottom, 100)
                }
                .refreshable { ek.fetchEventsAround(currentMonth) }

                addButton
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventForm(ek: ek, date: selectedDate, currentMonth: $currentMonth, onDone: { showAddEvent = false })
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
        .onAppear { ek.fetchEventsAround(currentMonth) }
        .onChange(of: currentMonth) { _, _ in ek.fetchEventsAround(currentMonth) }
    }

    // MARK: - No Access

    private var noAccessView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 34))
                .foregroundColor(.appTextSec.opacity(0.3))
            Text("No calendar access")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.appTextSec.opacity(0.6))
            Button("Allow") {
                Task { await ek.requestAccess() }
            }
            .tint(.appText)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Schedule Header

    private var scheduleHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Schedule")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                Text(monthYearString)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.08 * 11)
                    .foregroundColor(.appTextSec.opacity(0.5))
            }
            Spacer()
            HStack(spacing: 16) {
                Button { moveMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appTextSec.opacity(0.5))
                }
                Button { moveMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appTextSec.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Weekday Row

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                Text(day)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.appTextSec.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        let days = monthDays
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: cols, spacing: 2) {
            ForEach(0..<days.count, id: \.self) { i in
                dayCell(days[i])
            }
        }
        .padding(.horizontal, 16)
    }

    private func dayCell(_ date: Date) -> some View {
        let isToday = cal.isDateInToday(date)
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let isCurrentMonth = cal.component(.month, from: date) == cal.component(.month, from: currentMonth)
        let hasEvents = !events(for: date).isEmpty

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedDate = date
            }
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.appText)
                        .frame(width: 28, height: 28)
                        .matchedGeometryEffect(id: "selected", in: selectionAnimation)
                } else if isToday {
                    Circle()
                        .stroke(Color.appText, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                }

                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 12, weight: isSelected || isToday ? .bold : .medium, design: .rounded))
                    .foregroundColor(
                        isSelected ? .white :
                        isCurrentMonth ? .appText :
                        .appTextSec.opacity(0.25)
                    )

                if hasEvents && !isToday {
                    Circle()
                        .fill(Color.appText)
                        .frame(width: 4, height: 4)
                        .offset(y: 11)
                }
            }
            .frame(height: 34)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Daily Agenda

    private var dailyAgenda: some View {
        let dayEvents = events(for: selectedDate)

        return VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(Color.appBorder.opacity(0.3))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            HStack {
                Text(formattedSelectedDate)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.appTextSec.opacity(0.7))
                Spacer()
                Text("\(dayEvents.count) events")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.appTextSec.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            if dayEvents.isEmpty {
                Text("No events for this day")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.appTextSec.opacity(0.3))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            } else {
                timelineView(dayEvents)
            }
        }
        .padding(.bottom, 16)
    }

    private func timelineView(_ events: [EKEvent]) -> some View {
        let hourHeight: CGFloat = 52
        let startHour = max(0, (events.map { cal.component(.hour, from: $0.startDate) }.min() ?? 6) - 1)
        let endHour = min(23, (events.map { cal.component(.hour, from: $0.endDate) }.max() ?? 22) + 2)
        let totalHeight = CGFloat(endHour - startHour + 1) * hourHeight

        return ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // Hour lines
                VStack(spacing: 0) {
                    ForEach(startHour...endHour, id: \.self) { h in
                        HStack(spacing: 8) {
                            Text(String(format: "%02d:00", h))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.appTextSec.opacity(0.3))
                                .frame(width: 36, alignment: .trailing)
                            Rectangle()
                                .fill(.appBorder.opacity(0.15))
                                .frame(height: 1)
                        }
                        .frame(height: hourHeight)
                    }
                }

                // Event cards positioned by time
                ForEach(events, id: \.eventIdentifier) { event in
                    let eventStart = cal.component(.hour, from: event.startDate) * 60 + cal.component(.minute, from: event.startDate)
                    let eventEnd = cal.component(.hour, from: event.endDate) * 60 + cal.component(.minute, from: event.endDate)
                    let dayStart = startHour * 60
                    let startOffset = CGFloat(eventStart - dayStart) / 60 * hourHeight
                    let duration = max(CGFloat(eventEnd - eventStart) / 60 * hourHeight, hourHeight / 2)

                    Button {
                        selectedEvent = event
                    } label: {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(event.calendar.cgColor))
                                .frame(width: 4)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title ?? "Untitled")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.appText)
                                    .lineLimit(2)
                                if !event.isAllDay {
                                    Text("\(timeString(event.startDate, timeZone: event.timeZone))–\(timeString(event.endDate, timeZone: event.timeZone))")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(.appTextSec.opacity(0.5))
                                }
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(Color(event.calendar.cgColor).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .offset(y: startOffset)
                    .frame(height: max(duration - 4, hourHeight / 2))
                    .padding(.leading, 48)
                    .padding(.trailing, 8)
                }
            }
            .frame(height: totalHeight)
            .padding(.horizontal, 8)
        }
        .frame(maxHeight: 300)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showAddEvent = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.appText)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 80)
    }

    // MARK: - Helpers

    private func timeString(_ date: Date, timeZone: TimeZone? = nil) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        if let tz = timeZone { df.timeZone = tz }
        return df.string(from: date)
    }

    private var monthYearString: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.string(from: currentMonth)
    }

    private var formattedSelectedDate: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMMM d"
        return df.string(from: selectedDate)
    }

    private func moveMonth(_ offset: Int) {
        if let m = cal.date(byAdding: .month, value: offset, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentMonth = m
            }
        }
    }

    private var monthDays: [Date] {
        let start = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))!
        let range = cal.range(of: .day, in: .month, for: start)!
        let first = cal.component(.weekday, from: start)
        let offset = (first + 7 - cal.firstWeekday) % 7

        var days: [Date] = []

        if offset > 0 {
            for i in (1...offset).reversed() {
                if let d = cal.date(byAdding: .day, value: -i, to: start) {
                    days.append(d)
                }
            }
        }

        for day in 0..<range.count {
            if let d = cal.date(byAdding: .day, value: day, to: start) {
                days.append(d)
            }
        }

        let remaining = (7 - days.count % 7) % 7
        if remaining > 0, let last = days.last {
            for i in 1...remaining {
                if let d = cal.date(byAdding: .day, value: i, to: last) {
                    days.append(d)
                }
            }
        }

        return days
    }

    private func events(for date: Date) -> [EKEvent] {
        ek.events.filter { cal.isDate($0.startDate, inSameDayAs: date) }
    }
}

// MARK: - Event Detail View

struct EventDetailView: View {
    let event: EKEvent
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Title")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(event.title ?? "Untitled")
                            .multilineTextAlignment(.trailing)
                    }

                    if let loc = event.location, !loc.isEmpty {
                        HStack {
                            Text("Location")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(loc)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    HStack {
                        Text("All-day")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(event.isAllDay ? "Yes" : "No")
                    }

                    HStack {
                        Text("Starts")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(event.startDate, style: event.isAllDay ? .date : .time)
                    }

                    HStack {
                        Text("Ends")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(event.endDate, style: event.isAllDay ? .date : .time)
                    }

                    HStack {
                        Text("Calendar")
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(event.calendar.cgColor))
                                .frame(width: 8, height: 8)
                            Text(event.calendar.title)
                        }
                    }
                }

                if let notes = event.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Event Form

struct AddEventForm: View {
    @Bindable var ek: EventKitManager
    let date: Date
    @Binding var currentMonth: Date
    let onDone: () -> Void

    @State private var title = ""
    @State private var location = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes = ""
    @State private var isAllDay = false
    @State private var selectedCalendar: EKCalendar?

    init(ek: EventKitManager, date: Date, currentMonth: Binding<Date>, onDone: @escaping () -> Void) {
        self.ek = ek
        self.date = date
        self._currentMonth = currentMonth
        self.onDone = onDone
        let start = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
        self._startDate = State(initialValue: start)
        self._endDate = State(initialValue: start.addingTimeInterval(3600))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Location", text: $location)
                    Toggle("All-day", isOn: $isAllDay)
                    DatePicker("Starts", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    DatePicker("Ends", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                Section {
                    Picker("Calendar", selection: $selectedCalendar) {
                        ForEach(ek.calendarEventLists, id: \.calendarIdentifier) { cal in
                            HStack {
                                Circle()
                                    .fill(Color(cal.cgColor))
                                    .frame(width: 10, height: 10)
                                Text(cal.title)
                            }
                            .tag(cal as EKCalendar?)
                        }
                    }
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Notes")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDone() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let t = title.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty {
                            ek.createEvent(
                                title: t,
                                location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location,
                                startDate: startDate,
                                endDate: endDate,
                                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes,
                                calendar: selectedCalendar ?? ek.calendarEventLists.first,
                                isAllDay: isAllDay
                            )
                            ek.fetchEventsAround(currentMonth)
                        }
                        onDone()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
