import SwiftUI
import EventKit

struct TasksView: View {
    @Bindable var ek: EventKitManager

    var body: some View {
        VStack(spacing: 0) {
            if !ek.remindersGranted {
                VStack(spacing: 12) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Нет доступа к напоминаниям")
                        .foregroundColor(.white.opacity(0.6))
                    Button("Разрешить") {
                        Task { await ek.requestAccess() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else if ek.remindersError && ek.reminders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.icloud")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Не удалось загрузить задачи")
                        .foregroundColor(.white.opacity(0.7))
                    Button("Повторить") {
                        ek.refresh()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else {
                Picker("Список", selection: Bindable(ek).selectedList) {
                    ForEach(ek.reminderLists, id: \.calendarIdentifier) { list in
                        Text(list.title).tag(list as EKCalendar?)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if ek.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(ek.reminders, id: \.calendarItemIdentifier) { reminder in
                                Button {
                                    ek.toggleComplete(reminder)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "circle")
                                            .font(.title2)
                                            .foregroundColor(.white.opacity(0.6))

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(reminder.title ?? "Без названия")
                                                .foregroundColor(.white)
                                                .font(.body)
                                                .multilineTextAlignment(.leading)

                                            if let due = reminder.dueDateComponents?.date {
                                                Text(due, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                        }

                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 16)
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .refreshable {
                        ek.refresh()
                    }
                }
            }
        }
    }
}
