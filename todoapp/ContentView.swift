import SwiftUI

struct ContentView: View {
    @Environment(EventKitManager.self) var ek
    @State private var selectedPage = 1

    var body: some View {
        TabView(selection: $selectedPage) {
            NotesView()
                .tag(0)

            TasksView(ek: ek)
                .tag(1)

            CalendarView(ek: ek)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.18, blue: 0.25),
                         Color(red: 0.08, green: 0.1, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .task {
            if !ek.remindersGranted || !ek.calendarGranted {
                await ek.requestAccess()
            } else {
                ek.fetchLists()
                ek.fetchReminders()
                ek.fetchEvents()
            }
        }
        .overlay(alignment: .bottom) {
            HStack(spacing: 8) {
                Circle().fill(selectedPage == 0 ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                Circle().fill(selectedPage == 1 ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
                Circle().fill(selectedPage == 2 ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            .padding(.bottom, 12)
        }
        .overlay(alignment: .bottomTrailing) {
            Text(selectedPage == 0 ? "Заметки" : selectedPage == 1 ? "Задачи" : "Календарь")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .padding(.trailing, 16)
                .padding(.bottom, 30)
        }
    }
}
