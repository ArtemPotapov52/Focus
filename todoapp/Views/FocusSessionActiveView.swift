import SwiftUI
import EventKit

struct FocusSessionActiveView: View {
    @Bindable var ek: EventKitManager
    let session: FocusSessionManager
    let onExit: () -> Void

    @State private var showExitAlert = false
    @State private var completingId: String?
    @AppStorage("hide_session_exit_hint") private var hideExitHint = false

    private let cal = Calendar.current

    private var todayEvents: [EKEvent] {
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        return ek.events.filter { $0.startDate >= today && $0.startDate < tomorrow }
    }

    private var hasEvents: Bool {
        session.showCalendar && !todayEvents.isEmpty
    }

    private func timeString(_ date: Date, timeZone: TimeZone?) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        df.timeZone = timeZone ?? .current
        return df.string(from: date)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if session.sessionComplete {
                    completionView
                } else {
                    HStack(spacing: 0) {
                        if hasEvents {
                            calendarColumn
                                .frame(width: geo.size.width / 3)
                        }

                        tasksColumn
                            .frame(width: hasEvents ? geo.size.width * 2 / 3 : geo.size.width)
                    }
                }

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
        }
        .ignoresSafeArea()
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 5)
                .onEnded { _ in
                    showExitAlert = true
                }
        )
        .confirmationDialog("Exit Focus Session?", isPresented: $showExitAlert, titleVisibility: .visible) {
            Button("Exit Session", role: .destructive) {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
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
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
        .onDisappear {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
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
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
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
                .padding(.leading, 16)
                .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(todayEvents, id: \.eventIdentifier) { event in
                        eventRow(event)
                    }
                }
            }

            Spacer()
        }
    }

    private func eventRow(_ event: EKEvent) -> some View {
        let now = Date()
        let opacity: Double
        if event.endDate < now { opacity = 0.2 }
        else if event.startDate <= now && event.endDate >= now { opacity = 0.3 }
        else { opacity = 0.08 }

        return HStack(spacing: 8) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(timeString(event.startDate, timeZone: event.timeZone))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                if !event.isAllDay {
                    Text(timeString(event.endDate, timeZone: event.timeZone))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 38)

            Text(event.title ?? "")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(opacity))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    // MARK: - Tasks Column

    private var tasksColumn: some View {
        ZStack {
            // Header pinned at top
            VStack(spacing: 0) {
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
                .padding(.horizontal, 20)
                .padding(.top, 16)
                Spacer()
            }

            // Tasks centered vertically
            VStack(spacing: 4) {
                if let current = session.currentTask {
                    let isAnimating = completingId == current.calendarItemIdentifier
                    Text(current.title ?? "")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .strikethrough(isAnimating)
                        .overlay(alignment: .leading) {
                            if isAnimating {
                                GeometryReader { geo in
                                    Color.white
                                        .frame(width: geo.size.width, height: 4)
                                        .offset(y: geo.size.height / 2 - 2)
                                }
                                .transition(.scale(scale: 0, anchor: .leading))
                            }
                        }
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !isAnimating else { return }
                            completeTask(current)
                        }
                        .opacity(isAnimating ? 0.3 : 1)
                        .padding(.bottom, 10)
                }

                ForEach(Array(session.upcomingTasks.prefix(5).enumerated()), id: \.element.calendarItemIdentifier) { index, task in
                    let step = min(index, 4)
                    Text(task.title ?? "")
                        .font(.system(size: CGFloat(24 - step * 2), weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(max(0.2, 0.6 - Double(step) * 0.09)))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                }

                if session.upcomingTasks.count > 5 {
                    Text("+ \(session.upcomingTasks.count - 5) more")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.2))
                }
            }
        }
        .animation(.smooth(duration: 0.35), value: session.currentIndex)
    }

    private func completeTask(_ task: EKReminder) {
        let id = task.calendarItemIdentifier
        withAnimation(.easeInOut(duration: 0.35)) {
            completingId = id
        }

        try? ek.store.remove(task, commit: true)
        ek.reminders.removeAll { $0.calendarItemIdentifier == id }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.smooth(duration: 0.35)) {
                session.moveNext()
                completingId = nil
            }
        }
    }
}
