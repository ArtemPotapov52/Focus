import WidgetKit
import SwiftUI
import EventKit

struct StatsEntry: TimelineEntry {
    let date: Date
    let completedToday: Int
    let totalIncomplete: Int
}

struct StatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(date: Date(), completedToday: 0, totalIncomplete: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        Task { completion(await entry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        Task {
            let entry = await entry()
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    func entry() async -> StatsEntry {
        let store = EKEventStore()
        do {
            try await store.requestFullAccessToReminders()
            let predicate = store.predicateForReminders(in: nil)
            let all = await withCheckedContinuation { cont in
                store.fetchReminders(matching: predicate) { all in
                    cont.resume(returning: all ?? [])
                }
            }
            let cal = Calendar.current
            let todayComps = cal.dateComponents([.year, .month, .day], from: Date())
            let completedToday = all.filter {
                guard $0.isCompleted, let cd = $0.completionDate else { return false }
                let comps = cal.dateComponents([.year, .month, .day], from: cd)
                return comps.year == todayComps.year && comps.month == todayComps.month && comps.day == todayComps.day
            }.count
            let totalIncomplete = all.filter { !$0.isCompleted }.count
            return StatsEntry(date: Date(), completedToday: completedToday, totalIncomplete: totalIncomplete)
        } catch {
            return StatsEntry(date: Date(), completedToday: 0, totalIncomplete: 0)
        }
    }
}

struct StatsWidgetEntryView: View {
    var entry: StatsEntry

    private var dateString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.dateFormat = "EEEE, MMM"
        return df.string(from: entry.date)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: entry.date))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(dateString)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxHeight: .infinity)

            Divider()
                .background(.primary.opacity(0.08))
                .padding(.horizontal, 20)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.completedToday)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("/\(entry.totalIncomplete)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.background, for: .widget)
    }
}

struct StatsWidget: Widget {
    let kind: String = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Stats")
        .description("Today's date and task progress")
        .supportedFamilies([.systemSmall])
    }
}
