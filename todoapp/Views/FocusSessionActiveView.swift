import SwiftUI
import EventKit
import SwiftData

struct FocusSessionActiveView: View {
    @Environment(\.modelContext) private var context
    @Bindable var ek: EventKitManager
    let session: FocusSessionManager
    let onExit: () -> Void

    @State private var showExitAlert = false
    @State private var completingId: String?
    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var savedNote = false
    @AppStorage("hide_session_exit_hint") private var hideExitHint = false

    private let cal = Calendar.current

    private var todayEvents: [EKEvent] {
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        return ek.events.filter { $0.startDate >= today && $0.startDate < tomorrow }
    }

    private func timeString(_ date: Date, timeZone: TimeZone?) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        df.timeZone = timeZone ?? .current
        return df.string(from: date)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if session.sessionComplete {
                completionView
            } else {
                HStack(spacing: 0) {
                    if session.showCalendar {
                        calendarColumn
                            .frame(maxWidth: .infinity)
                        Divider().background(Color.white.opacity(0.12))
                    }

                    tasksColumn
                        .frame(maxWidth: .infinity)

                    if session.showNotes {
                        Divider().background(Color.white.opacity(0.12))
                        notesColumn
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Exit hint overlay
            if !hideExitHint && !session.sessionComplete {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 12))
                        Text("Hold screen 5s to exit")
                            .font(.system(size: 11, design: .rounded))
                    }
                    .foregroundColor(Color.white.opacity(0.25))
                    .padding(.bottom, 40)
                }
                .allowsHitTesting(false)
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 5)
                .onEnded { _ in
                    showExitAlert = true
                }
        )
        .confirmationDialog("Exit Focus Session?", isPresented: $showExitAlert, titleVisibility: .visible) {
            Button("Exit Session", role: .destructive) {
                session.reset()
                onExit()
            }
            Button("Don't Show Hint Again") {
                hideExitHint = true
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Long press anywhere for 5 seconds to exit")
        }
        .onChange(of: session.sessionComplete) { _, done in
            if done {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.white)

            Text("Session Complete")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(session.completedTasks.count) task\(session.completedTasks.count == 1 ? "" : "s") done")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(Color.white.opacity(0.5))

            Spacer()

            Button {
                session.reset()
                onExit()
            } label: {
                Text("Close")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Calendar Column

    private var calendarColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.4))
                .tracking(2)
                .padding(.top, 16)
                .padding(.leading, 12)
                .padding(.bottom, 10)

            if todayEvents.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                    Text("No events")
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundColor(Color.white.opacity(0.2))
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(todayEvents, id: \.eventIdentifier) { event in
                            eventRow(event)
                        }
                    }
                }
            }

            Spacer()
        }
    }

    private func eventRow(_ event: EKEvent) -> some View {
        let now = Date()
        let opacity: Double
        if event.endDate < now { opacity = 0.15 }
        else if event.startDate <= now && event.endDate >= now { opacity = 0.25 }
        else { opacity = 0.06 }

        return HStack(spacing: 6) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(timeString(event.startDate, timeZone: event.timeZone))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                if !event.isAllDay {
                    Text(timeString(event.endDate, timeZone: event.timeZone))
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title ?? "")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                if let loc = event.location, !loc.isEmpty {
                    Text(loc)
                        .font(.system(size: 9, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    // MARK: - Tasks Column

    private var tasksColumn: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("TASKS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.4))
                    .tracking(2)
                Spacer()
                Text("\(session.currentIndex + 1)/\(session.selectedTasks.count)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Current task
            if let current = session.currentTask {
                let isAnimating = completingId == current.calendarItemIdentifier
                currentTaskCard(current, isAnimating: isAnimating)
            }

            // Remaining tasks
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(session.upcomingTasks, id: \.calendarItemIdentifier) { task in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 6, height: 6)
                            Text(task.title ?? "")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.3))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 4)
            }
        }
        .animation(.smooth(duration: 0.35), value: session.currentIndex)
    }

    private func currentTaskCard(_ task: EKReminder, isAnimating: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACTIVE")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.3))
                .tracking(2)
                .padding(.leading, 2)

            Text(task.title ?? "")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .strikethrough(isAnimating)
                .overlay(alignment: .leading) {
                    if isAnimating {
                        GeometryReader { geo in
                            Color.white
                                .frame(width: geo.size.width, height: 2.5)
                                .offset(y: geo.size.height / 2 - 1.25)
                        }
                        .transition(.scale(scale: 0, anchor: .leading))
                    }
                }
                .lineLimit(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isAnimating else { return }
            completeTask(task)
        }
        .opacity(isAnimating ? 0.5 : 1)
    }

    private func completeTask(_ task: EKReminder) {
        let id = task.calendarItemIdentifier
        withAnimation(.easeInOut(duration: 0.35)) {
            completingId = id
        }

        ek.toggleComplete(task)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.smooth(duration: 0.35)) {
                session.moveNext()
                completingId = nil
            }
        }
    }

    // MARK: - Notes Column

    private var notesColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTES")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.4))
                .tracking(2)
                .padding(.top, 16)
                .padding(.leading, 12)

            TextField("Title", text: $noteTitle)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .tint(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 8)

            TextEditor(text: $noteContent)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 8)
                .frame(minHeight: 120)

            if savedNote {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Saved!")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color.white.opacity(0.5))
                .padding(.leading, 12)
            }

            Button {
                saveNote()
            } label: {
                Text("Save Note")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(noteTitle.isEmpty ? Color.white.opacity(0.3) : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(noteTitle.isEmpty)
            .padding(.horizontal, 8)

            Spacer()
        }
    }

    private func saveNote() {
        guard !noteTitle.isEmpty else { return }
        let note = Note(title: noteTitle, content: noteContent, category: "Productivity", imageData: nil)
        context.insert(note)
        try? context.save()
        noteTitle = ""
        noteContent = ""
        savedNote = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedNote = false
        }
    }
}
