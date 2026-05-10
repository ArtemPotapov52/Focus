import SwiftUI
import EventKit

struct CalendarView: View {
    @Bindable var ek: EventKitManager
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()
    @State private var showAdd = false
    @State private var newEventTitle = ""

    private let cal = Calendar.current
    private let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        VStack(spacing: 0) {
            if !ek.calendarGranted {
                noAccessView
            } else {
                ScrollView {
                    monthHeader
                    weekdayRow
                    dateGrid
                    selectedDateEvents
                }
                .refreshable {
                    ek.fetchEventsAround(currentMonth)
                }
            }

            if ek.calendarGranted {
                addButton
            }
        }
        .onAppear {
            ek.fetchEventsAround(currentMonth)
        }
        .onChange(of: currentMonth) { _, _ in
            ek.fetchEventsAround(currentMonth)
        }
        .sheet(isPresented: $showAdd) {
            addEventSheet
        }
    }

    // MARK: - No Access

    private var noAccessView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            Text("Нет доступа к календарю")
                .foregroundColor(.white.opacity(0.6))
            Button("Разрешить") {
                Task { await ek.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { moveMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text(monthYearString)
                .font(.title2.bold())
                .foregroundColor(.white)

            Spacer()

            Button { moveMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Weekday Row

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Date Grid

    private var dateGrid: some View {
        let days = monthDays
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: cols, spacing: 6) {
            ForEach(0..<days.count, id: \.self) { i in
                if let date = days[i] {
                    dateCell(date)
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fill)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func dateCell(_ date: Date) -> some View {
        let isToday = cal.isDateInToday(date)
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let isCurrentMonth = cal.component(.month, from: date) == cal.component(.month, from: currentMonth)
        let hasEvents = events(for: date).isEmpty == false

        return Button {
            selectedDate = date
        } label: {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(.white)
                        .frame(width: 34, height: 34)
                } else if isToday {
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: 34, height: 34)
                }

                Text("\(cal.component(.day, from: date))")
                    .font(.callout.weight(isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .black : isCurrentMonth ? .white : .white.opacity(0.25))
            }
            .frame(height: 38)
            .overlay(alignment: .bottom) {
                if hasEvents && !isSelected {
                    Circle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 4, height: 4)
                        .offset(y: -2)
                }
            }
        }
    }

    // MARK: - Events for Selected Date

    private var selectedDateEvents: some View {
        let dayEvents = events(for: selectedDate)
        let dayTasks = tasks(for: selectedDate)

        return VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(.white.opacity(0.1))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Text(formattedSelectedDate)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            if dayEvents.isEmpty && dayTasks.isEmpty {
                Text("Нет событий и задач")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
            } else {
                ForEach(dayEvents, id: \.eventIdentifier) { event in
                    eventRow(event)
                }
                ForEach(dayTasks, id: \.calendarItemIdentifier) { task in
                    taskRow(task)
                }
                .padding(.bottom, 120)
            }
        }
    }

    private func eventRow(_ event: EKEvent) -> some View {
        HStack(spacing: 10) {
            VStack(spacing: 2) {
                Text(event.startDate, style: .time)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                Text(event.endDate, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 58)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(event.calendar.cgColor))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "Без названия")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                if let loc = event.location, !loc.isEmpty {
                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }

    private func taskRow(_ task: EKReminder) -> some View {
        Button {
            ek.toggleComplete(task)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "circle")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 12)

                Text(task.title ?? "")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .strikethrough(task.isCompleted)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Button

    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    newEventTitle = ""
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.black)
                        .frame(width: 50, height: 50)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 6)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Add Event Sheet

    private var addEventSheet: some View {
        VStack(spacing: 20) {
            Text("Новое событие")
                .font(.title3.weight(.bold))

            TextField("Название события", text: $newEventTitle)
                .textFieldStyle(.plain)
                .font(.body)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                let t = newEventTitle.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty {
                    ek.addEvent(title: t, date: selectedDate)
                    ek.fetchEventsAround(currentMonth)
                }
                showAdd = false
            } label: {
                Text("Добавить")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.black)
                    .foregroundColor(newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()
        }
        .padding(24)
        .padding(.top, 20)
        .presentationDetents([.height(220)])
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "LLLL yyyy"
        return df.string(from: currentMonth).capitalized
    }

    private var formattedSelectedDate: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMMM, EEEE"
        return df.string(from: selectedDate).capitalized
    }

    private func moveMonth(_ offset: Int) {
        if let m = cal.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = m
        }
    }

    private var monthDays: [Date?] {
        let start = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))!
        let range = cal.range(of: .day, in: .month, for: start)!
        let firstWeekday = cal.component(.weekday, from: start)
        let offset = (firstWeekday + 5) % 7

        var days: [Date?] = []
        for _ in 0..<offset { days.append(nil) }
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: start) {
                days.append(d)
            }
        }
        let remaining = (7 - days.count % 7) % 7
        for _ in 0..<remaining { days.append(nil) }
        return days
    }

    private func events(for date: Date) -> [EKEvent] {
        ek.events.filter { cal.isDate($0.startDate, inSameDayAs: date) }
    }

    private func tasks(for date: Date) -> [EKReminder] {
        ek.reminders.filter { rem in
            guard let due = rem.dueDateComponents?.date else { return false }
            return cal.isDate(due, inSameDayAs: date)
        }
    }
}
