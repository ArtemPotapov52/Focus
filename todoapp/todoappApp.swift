import SwiftUI
import SwiftData

@main
struct todoappApp: App {
    @State private var ek = EventKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(ek)
                .modelContainer(for: Note.self)
        }
    }
}
