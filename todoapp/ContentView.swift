import SwiftUI

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()

            VStack(spacing: 30) {
                Text("ПРИВЕТ")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("\(count)")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 20) {
                    Button("-") { count -= 1 }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    Button("+") { count += 1 }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                }
                .font(.title)

                Button("Сброс") { count = 0 }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
            }
        }
    }
}
