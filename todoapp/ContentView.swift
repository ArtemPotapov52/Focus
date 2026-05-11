import SwiftUI

struct ContentView: View {
    @Environment(EventKitManager.self) var ek
    @Environment(\.scenePhase) var scenePhase
    @State private var selectedPage = 0
    @State private var music = MusicManager()
    @State private var showProfile = false
    @State private var showFocusSession = false
    @State private var focusSession = FocusSessionManager()
    @State private var lastSceneRefresh = Date()
    @State private var keyboardVisible = false

    let tabs: [(icon: String, label: String)] = [
        ("circle", "Tasks"),
        ("doc.text", "Notes"),
        ("calendar", "Events"),
        ("sparkles", "AI"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top App Bar
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 18))
                            .foregroundColor(.appText)
                        Text("Focus")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.appText)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button { showFocusSession = true } label: {
                            Text("Session")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.appText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.appGrayBg)
                                .clipShape(Capsule())
                        }
                        AvatarIcon()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.appBg)

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
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showFocusSession) {
            FocusSessionFlow(ek: ek, session: focusSession, isPresented: $showFocusSession)
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
                            .foregroundColor(selectedPage == i ? .appText : Color.appTextSec.opacity(0.5))

                        Text(tabs[i].label)
                            .font(.custom("Plus Jakarta Sans", size: 11))
                            .fontWeight(selectedPage == i ? .bold : .medium)
                            .foregroundColor(selectedPage == i ? .appText : Color.appTextSec.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(Color.appBg.opacity(0.9))
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: "c4c7c7").opacity(0.1))
                .frame(height: 1)
        }
    }
}

struct AvatarIcon: View {
    var body: some View {
        Image(systemName: "person.circle")
            .font(.system(size: 22))
            .foregroundColor(Color(hex: "1a1c1c"))
    }
}

struct FocusSessionFlow: View {
    @Bindable var ek: EventKitManager
    let session: FocusSessionManager
    @Binding var isPresented: Bool

    var body: some View {
        Group {
            switch session.phase {
            case .idle, .setup:
                FocusSessionSetupView(ek: ek, session: session)
            case .active:
                FocusSessionActiveView(ek: ek, session: session, onExit: {
                    session.reset()
                    isPresented = false
                })
            }
        }
        .onChange(of: isPresented) { _, shown in
            if !shown {
                session.reset()
            }
        }
    }
}
