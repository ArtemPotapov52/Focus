import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct TodoWidgetsExtensionEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            Text("Привет!")
                .font(.title.bold())
            Text("todoapp")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct TodoWidgetsExtension: Widget {
    let kind: String = "TodoWidgetsExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TodoWidgetsExtensionEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("todoapp виджет")
        .description("Просто виджет с приветствием")
        .supportedFamilies([.systemSmall])
    }
}
