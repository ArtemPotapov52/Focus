import SwiftUI

struct ContentView: View {
    @Environment(EventKitManager.self) var ek
    @Environment(\.scenePhase) var scenePhase
    @State private var selectedPage = 0
    @State private var music = MusicManager()
    @State private var showFocus = false
    @State private var lastSceneRefresh = Date()
    @State private var keyboardVisible = false
    @AppStorage("ai_mode") private var aiMode = "focus"

    let tabs: [(icon: String, label: String)] = [
        ("circle", "Tasks"),
        ("doc.text", "Notes"),
        ("calendar", "Events"),
        ("sparkles", "AI"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "f9f9f9").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Bar (static — doesn't scroll with pages)
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "1a1c1c"))
                        Text("Focus")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "1a1c1c"))
                    }

                    if selectedPage == 3 {
                        Spacer()
                        Picker("Mode", selection: $aiMode) {
                            Text("Focus").tag("focus")
                            Text("Simple").tag("simple")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .scaleEffect(0.85)
                        Spacer()
                    } else {
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Button { showFocus = true } label: {
                            Image(systemName: "circle.dotted")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "1a1c1c").opacity(0.7))
                        }
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "1a1c1c"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: "f9f9f9"))

                TabView(selection: $selectedPage) {
                    TasksView(ek: ek)
                        .tag(0)

                    NotesView()
                        .tag(1)

                    CalendarView(ek: ek)
                        .tag(2)

                    ChatView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // Bottom Navigation
            if !keyboardVisible {
                navBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: keyboardVisible)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
        .task {
            if !ek.remindersGranted || !ek.calendarGranted {
                await ek.requestAccess()
            } else {
                ek.fetchLists()
                ek.fetchReminders()
                ek.fetchEventsAround(Date())
            }
        }
        .fullScreenCover(isPresented: $showFocus) {
            FocusView()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, Date().timeIntervalSince(lastSceneRefresh) > 2 else { return }
            lastSceneRefresh = Date()
            if ek.remindersGranted {
                ek.fetchLists()
                ek.fetchReminders()
            }
            if ek.calendarGranted {
                ek.fetchEventsAround(Date())
            }
        }
    }

    private var navBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button {
                    selectedPage = i
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tabs[i].icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedPage == i ? Color(hex: "1a1c1c") : Color(hex: "444748").opacity(0.5))

                        Text(tabs[i].label)
                            .font(.custom("Plus Jakarta Sans", size: 11))
                            .fontWeight(selectedPage == i ? .bold : .medium)
                            .foregroundColor(selectedPage == i ? Color(hex: "1a1c1c") : Color(hex: "444748").opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(Color(hex: "f9f9f9").opacity(0.9))
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: "c4c7c7").opacity(0.1))
                .frame(height: 1)
        }
    }
}
