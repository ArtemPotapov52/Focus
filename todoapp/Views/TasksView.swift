import SwiftUI
import EventKit

struct TasksView: View {
    @Bindable var ek: EventKitManager
    @State private var showQuickAdd = false
    @State private var newTaskTitle = ""

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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

            Button {
                newTaskTitle = ""
                showQuickAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(width: 54, height: 54)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showQuickAdd) {
            quickAddSheet
        }
    }

    private var quickAddSheet: some View {
        VStack(spacing: 20) {
            Text("Новая задача")
                .font(.title3.weight(.bold))

            TextField("Что нужно сделать?", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.body)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
                if !title.isEmpty {
                    ek.addReminder(title: title)
                }
                showQuickAdd = false
            } label: {
                Text("Добавить")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(!newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty ? Color.black : Color.gray.opacity(0.3))
                    .foregroundColor(!newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty ? .white : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()
        }
        .padding(24)
        .padding(.top, 20)
        .presentationDetents([.height(220)])
    }
}
