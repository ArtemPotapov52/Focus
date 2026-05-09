import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            Text("ПРИВЕТ")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        }
    }
}
