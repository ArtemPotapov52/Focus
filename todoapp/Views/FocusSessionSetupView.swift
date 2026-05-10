import SwiftUI
import EventKit

struct FocusSessionSetupView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var ek: EventKitManager
    let session: FocusSessionManager

    @State private var selectedIDs: Set<String> = []
    @State private var showCalendar = false
    @State private var selectedMinutes = 25

    let timeOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120, 180]

    private var allTasks: [EKReminder] {
        ek.reminders.filter { !$0.isCompleted }
    }

    private func timeLabel(_ min: Int) -> String {
        if min < 60 { return "\(min) min" }
        let h = min / 60
        return h == 1 ? "1 hour" : "\(h) hours"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color(hex: "444748"))
                Spacer()
                Text("Focus Session")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
                Spacer()
                Color.clear.frame(width: 44)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Selected count
            HStack {
                Text("Select tasks")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "444748").opacity(0.5))
                Spacer()
                Text("\(selectedIDs.count) selected")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Task list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(allTasks, id: \.calendarItemIdentifier) { task in
                        let id = task.calendarItemIdentifier
                        let isSel = selectedIDs.contains(id)
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSel ? Color(hex: "1a1c1c") : Color(hex: "c4c7c7"), lineWidth: isSel ? 2 : 1)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Group {
                                        if isSel {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundColor(Color(hex: "1a1c1c"))
                                        }
                                    }
                                )

                            Text(task.title ?? "")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "1a1c1c"))
                                .lineLimit(2)

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isSel { selectedIDs.remove(id) }
                            else { selectedIDs.insert(id) }
                        }
                        .background(Color(hex: "f9f9f9"))

                        Divider()
                            .padding(.leading, 52)
                            .opacity(0.3)
                    }
                }
            }

            // Bottom section
            VStack(spacing: 14) {
                Divider().padding(.horizontal, 20)

                // Checkboxes
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: showCalendar ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18))
                            .foregroundColor(showCalendar ? Color(hex: "1a1c1c") : Color(hex: "c4c7c7"))
                        Text("Show calendar events")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Color(hex: "1a1c1c"))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showCalendar.toggle() }
                }
                .padding(.horizontal, 20)

                // Time picker label
                HStack {
                    Text("Duration")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "444748").opacity(0.5))
                    Spacer()
                    Text(selectedMinutes < 60 ? "\(selectedMinutes) min" : "\(selectedMinutes / 60) h")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "1a1c1c"))
                }
                .padding(.horizontal, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 6) {
                        ForEach(timeOptions, id: \.self) { min in
                            Text(timeLabel(min))
                                .font(.system(size: 15, weight: selectedMinutes == min ? .semibold : .medium, design: .rounded))
                                .foregroundColor(selectedMinutes == min ? .white : Color(hex: "1a1c1c"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedMinutes == min ? Color(hex: "1a1c1c") : Color(hex: "eeeeee"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .contentShape(Rectangle())
                                .onTapGesture { selectedMinutes = min }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 160)

                // Start button
                Button {
                    session.selectedTasks = allTasks.filter { selectedIDs.contains($0.calendarItemIdentifier) }
                    session.showCalendar = showCalendar
                    session.duration = TimeInterval(selectedMinutes * 60)
                    session.currentIndex = 0
                    session.sessionComplete = false
                    session.phase = .active
                } label: {
                    Text("Start Session")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedIDs.isEmpty ? Color(hex: "c4c7c7") : Color(hex: "1a1c1c"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedIDs.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(hex: "ffffff"))
        }
        .background(Color(hex: "f9f9f9"))
    }
}
