import SwiftUI
import EventKit

struct FocusView: View {
    @Environment(EventKitManager.self) var ek
    @State private var focus = FocusManager()
    @State private var selectedMinutes: Double = 25
    @State private var showDurationPicker = false

    private let presets: [Double] = [5, 10, 15, 25, 30, 45, 60]

    var body: some View {
        ZStack {
            if focus.state == .idle {
                idleView
            } else {
                activeView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))

            Text("Фокус")
                .font(.title.weight(.bold))
                .foregroundColor(.white)

            Text("Выбери время")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { min in
                    Button(min.formatted(.number) + "м") {
                        selectedMinutes = min
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedMinutes == min
                            ? Color.white
                            : Color.white.opacity(0.1)
                    )
                    .foregroundColor(selectedMinutes == min ? .black : .white)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)

            Button {
                focus.setDuration(selectedMinutes)
                withAnimation(.smooth) { focus.start() }
            } label: {
                Label("Начать", systemImage: "play.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 0) {
            // top bar
            HStack {
                Button("Закончить") {
                    withAnimation(.smooth) { focus.finish() }
                }
                .foregroundColor(.red.opacity(0.8))
                .font(.subheadline.weight(.medium))

                Spacer()

                Button {
                    withAnimation { focus.togglePause() }
                } label: {
                    Image(systemName: focus.state == .paused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            Spacer()

            // timer
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 220, height: 220)

                Circle()
                    .trim(from: 0, to: focus.progress)
                    .stroke(Color.white, style: .init(lineWidth: 6, lineCap: .round))
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(focus.remainingString)
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text(focus.state == .paused ? "Пауза" : "Фокус")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            // tasks
            if !ek.reminders.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Задачи на сегодня")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.leading, 4)

                    ForEach(ek.reminders.prefix(5), id: \.calendarItemExternalIdentifier) { reminder in
                        HStack(spacing: 8) {
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(reminder.isCompleted ? .green : .white.opacity(0.4))
                                .font(.caption)

                            Text(reminder.title)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(reminder.isCompleted ? 0.3 : 0.8))
                                .strikethrough(reminder.isCompleted)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            } else {
                Text("Нет задач на сегодня")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 40)
            }
        }
    }
}
