import WidgetKit
import SwiftUI
import EventKit

struct CalendarEntry: TimelineEntry {
    let date: Date
    let events: [EKEvent]
}

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), events: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        Task { completion(await entry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        Task {
            let entry = await entry()
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date) ?? entry.date.addingTimeInterval(900)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    func entry() async -> CalendarEntry {
        let store = EKEventStore()
        do {
            try await store.requestFullAccessToEvents()
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
            let predicate = store.predicateForEvents(withStart: today, end: tomorrow, calendars: nil)
            let all = store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
            var seen = Set<String>()
            let unique = all.filter {
                let key = "\($0.startDate.timeIntervalSince1970)-\($0.title ?? "")-\($0.eventIdentifier ?? $0.calendarItemExternalIdentifier)"
                return seen.insert(key).inserted
            }
            return CalendarEntry(date: Date(), events: Array(unique.prefix(4)))
        } catch {
            return CalendarEntry(date: Date(), events: [])
        }
    }
}

struct CalendarWidgetEntryView: View {
    var entry: CalendarEntry

    var body: some View {
        VStack(spacing: 0) {
            if entry.events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                    Text("Focus")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(maxHeight: .infinity)
            } else {
                Text("TODAY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                    .padding(.bottom, 8)

                VStack(spacing: 8) {
                    ForEach(Array(entry.events.enumerated()), id: \.offset) { _, event in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.primary)
                                .frame(width: 6, height: 6)

                            Text(event.title ?? "")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 4)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(14)
        .containerBackground(.background, for: .widget)
    }
}

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("Today's events")
        .supportedFamilies([.systemSmall])
    }
}
