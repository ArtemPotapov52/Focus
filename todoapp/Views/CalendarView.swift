import SwiftUI
import EventKit

struct CalendarView: View {
    @Bindable var ek: EventKitManager

    var body: some View {
        VStack(spacing: 0) {
            if !ek.calendarGranted {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Нет доступа к календарю")
                        .foregroundColor(.white.opacity(0.6))
                    Button("Разрешить") {
                        Task { await ek.requestAccess() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else {
                HStack {
                    Text("Календарь")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                if ek.events.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 34))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Нет событий на ближайшие дни")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(ek.events.prefix(30)), id: \.eventIdentifier) { event in
                                HStack(spacing: 12) {
                                    VStack(spacing: 2) {
                                        Text(event.startDate, style: .time)
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                        Text(event.endDate, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .frame(width: 64)

                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(event.calendar.cgColor))
                                        .frame(width: 4)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title ?? "Без названия")
                                            .font(.body.bold())
                                            .foregroundColor(.white)
                                        if let loc = event.location, !loc.isEmpty {
                                            Text(loc)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)

                                if event != ek.events.prefix(30).last {
                                    Divider()
                                        .background(.white.opacity(0.1))
                                        .padding(.leading, 92)
                                }
                            }
                        }
                    }
                    .refreshable {
                        ek.refresh()
                    }
                }
            }
        }
    }
}
