import SwiftUI
import EventKit

struct TasksView: View {
    @Bindable var ek: EventKitManager
    @State private var showAdd = false
    @State private var selectedCategory: EKCalendar?
    @State private var completingTaskId: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Today Header + Category Picker
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Today")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.appText)

                                Text(todayString.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(0.08 * 11)
                                    .foregroundColor(.appTextSec.opacity(0.5))
                            }

                            Spacer()

                            Menu {
                                Button { selectedCategory = nil } label: {
                                    HStack {
                                        Text("All")
                                        if selectedCategory == nil { Image(systemName: "checkmark") }
                                    }
                                }
                                ForEach(ek.reminderLists, id: \.calendarIdentifier) { list in
                                    Button { selectedCategory = list } label: {
                                        HStack {
                                            Text(list.title)
                                            if selectedCategory?.calendarIdentifier == list.calendarIdentifier {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedCategory?.title ?? "All")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.appTextSec.opacity(0.6))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.appTextSec.opacity(0.4))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.appGrayBg)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 20)

                        if !ek.remindersGranted {
                            noAccessView
                        } else {
                            let all = filteredTasks
                            if all.isEmpty {
                                emptyView
                            } else {
                                let incomplete = all.filter { !$0.isCompleted }
                                let completed = all.filter { $0.isCompleted }
                                    .sorted { ($0.completionDate ?? .distantPast) > ($1.completionDate ?? .distantPast) }

                                let morning = tasksInRange(incomplete, 0..<12)
                                let afternoon = tasksInRange(incomplete, 12..<17)
                                let evening = tasksInRange(incomplete, 17..<24)

                                if !morning.isEmpty {
                                    taskSection(title: "MORNING", count: morning.count, tasks: morning)
                                }
                                if !afternoon.isEmpty {
                                    taskSection(title: "AFTERNOON", count: afternoon.count, tasks: afternoon)
                                }
                                if !evening.isEmpty {
                                    taskSection(title: "EVENING", count: evening.count, tasks: evening)
                                }
                                if !completed.isEmpty {
                                    completedSection(completed)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                .animation(.smooth(duration: 0.5), value: ek.reminders.filter { $0.isCompleted }.count)
            }

            // FAB
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(.appText)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 80)
        }
        .sheet(isPresented: $showAdd) {
            AddTaskView(ek: ek, defaultList: selectedCategory, selectedCategory: $selectedCategory)
        }
    }

    // MARK: - No Access

    private var noAccessView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 34))
                .foregroundColor(.appTextSec.opacity(0.5))
            Text("Нет доступа к напоминаниям")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.appTextSec.opacity(0.6))
            Button("Разрешить") {
                Task { await ek.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.appText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 34))
                .foregroundColor(.appTextSec.opacity(0.3))
            Text("Нет задач")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.appTextSec.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Filter

    private var filteredTasks: [EKReminder] {
        if let cat = selectedCategory {
            return ek.reminders.filter { $0.calendar?.calendarIdentifier == cat.calendarIdentifier }
        }
        return ek.reminders
    }

    private func tasksInRange(_ tasks: [EKReminder], _ range: Range<Int>) -> [EKReminder] {
        tasks.filter { task in
            guard let d = task.dueDateComponents?.date else { return range == 0..<12 }
            let h = Calendar.current.component(.hour, from: d)
            return range.contains(h)
        }
    }

    // MARK: - Sections

    private func taskSection(title: String, count: Int, tasks: [EKReminder]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.08 * 10)
                    .foregroundColor(.appTextSec.opacity(0.6))

                Spacer()

                Text("\(count) TASKS")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.appTextSec.opacity(0.3))
            }
            .padding(.bottom, 4)
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(tasks, id: \.calendarItemIdentifier) { task in
                    TaskRowView(
                        task: task,
                        isCompleted: false,
                        ek: ek,
                        isAnimating: completingTaskId == task.calendarItemIdentifier,
                        onComplete: { startComplete(task) }
                    )
                    .padding(.vertical, 6)
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            }
        }
        .padding(.bottom, 16)
    }

    private func completedSection(_ tasks: [EKReminder]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("COMPLETED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.08 * 10)
                    .foregroundColor(.appTextSec.opacity(0.4))

                Spacer()

                Text("\(tasks.count) TASKS")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.appTextSec.opacity(0.2))
            }
            .padding(.bottom, 4)
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(tasks, id: \.calendarItemIdentifier) { task in
                    TaskRowView(
                        task: task,
                        isCompleted: true,
                        ek: ek,
                        isAnimating: false,
                        onComplete: {}
                    )
                    .padding(.vertical, 6)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .identity
                    ))
                }
            }
        }
        .padding(.bottom, 16)
    }

    private func startComplete(_ task: EKReminder) {
        let id = task.calendarItemIdentifier
        completingTaskId = id

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.smooth(duration: 0.4)) {
                ek.toggleComplete(task)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completingTaskId = nil
            }
        }
    }

    // MARK: - Helpers

    private var todayString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.dateFormat = "MMMM dd, yyyy"
        return df.string(from: Date())
    }
}

// MARK: - Task Row

struct TaskRowView: View {
    let task: EKReminder
    let isCompleted: Bool
    let ek: EventKitManager
    let isAnimating: Bool
    let onComplete: () -> Void

    @State private var sweepWidth: CGFloat = 0
    @State private var checkScale: CGFloat = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Circle
            Button {
                if !isCompleted { onComplete() }
            } label: {
                ZStack {
                    Circle()
                        .stroke(isCompleted || isAnimating ? Color.clear : .appBorder.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isCompleted || isAnimating {
                        Circle()
                            .fill(.appText)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .scaleEffect(isCompleted ? 1 : checkScale)
                    }
                }
            }
            .padding(.top, 3)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title ?? "")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(isCompleted ? .appTextSec.opacity(0.3) : .appText)
                    .strikethrough(isCompleted)
                    .lineLimit(2)
                    .overlay(alignment: .leading) {
                        if isAnimating {
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(.appBorder.opacity(0.5))
                                    .frame(width: geo.size.width * sweepWidth, height: 1.5)
                                    .offset(y: geo.size.height / 2 - 0.75)
                            }
                        }
                    }

                HStack(spacing: 6) {
                    if let due = task.dueDateComponents?.date {
                        Text(relativeDateString(due))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(isCompleted ? .appTextSec.opacity(0.15) : .appTextSec.opacity(0.6))
                    }
                    if let list = task.calendar {
                        Text(list.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(isCompleted ? .appTextSec.opacity(0.1) : .appTextSec.opacity(0.35))
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 2)
        .opacity(isAnimating ? 0.6 : 1)
        .onChange(of: isAnimating) { _, new in
            if new {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    checkScale = 1
                }
                withAnimation(.easeInOut(duration: 0.35).delay(0.05)) {
                    sweepWidth = 1
                }
            } else {
                sweepWidth = 0
                checkScale = 0
            }
        }
    }

    private func relativeDateString(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "hh:mm a"
            return df.string(from: date)
        }
        if cal.isDateInYesterday(date) {
            return "Yesterday"
        }
        if cal.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "EEEE"
            return df.string(from: date)
        }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }
}

// MARK: - Add Task Sheet

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var ek: EventKitManager
    var defaultList: EKCalendar?
    @Binding var selectedCategory: EKCalendar?

    @State private var title = ""
    @State private var dueDate = Date().addingTimeInterval(3600)
    @State private var hasDueDate = false
    @State private var selectedList: EKCalendar?
    @AppStorage("default_list_id") private var defaultListId: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.appTextSec.opacity(0.6))

                Spacer()

                Text("New Task")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appText)

                Spacer()

                Button("Add") {
                    let t = title.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty {
                        let list = selectedList ?? defaultList ?? ek.selectedList
                        ek.addReminder(title: t, list: list)
                        if let l = list {
                            selectedCategory = l
                            defaultListId = l.calendarIdentifier
                        }
                    }
                    dismiss()
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.appText)
                .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)

            TextField("What do you need to do?", text: $title)
                .font(.system(size: 17, design: .rounded))
                .foregroundColor(.appText)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.appGrayBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            Button {
                withAnimation(.smooth) { hasDueDate.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: hasDueDate ? "calendar.circle.fill" : "calendar.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.appText)
                    Text("Due Date")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.appText)
                    Spacer()
                    if hasDueDate {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSec.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }

            if hasDueDate {
                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if !ek.reminderLists.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "list.bullet.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.appText)
                    Picker("List", selection: $selectedList) {
                        Text(defaultListId.isEmpty ? "Default" : ek.reminderLists.first(where: { $0.calendarIdentifier == defaultListId })?.title ?? "Default").tag(nil as EKCalendar?)
                        ForEach(ek.reminderLists, id: \.calendarIdentifier) { list in
                            Text(list.title).tag(list as EKCalendar?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.appText)
                    .font(.system(size: 15, design: .rounded))
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Spacer()
        }
        .presentationDetents([.large])
        .onAppear {
            selectedList = defaultList ?? ek.selectedList
            if let id = defaultListId.isEmpty ? nil : defaultListId,
               let saved = ek.reminderLists.first(where: { $0.calendarIdentifier == id })
            {
                selectedList = saved
            }
        }
        .onChange(of: selectedList) { _, list in
            if let l = list { defaultListId = l.calendarIdentifier }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
