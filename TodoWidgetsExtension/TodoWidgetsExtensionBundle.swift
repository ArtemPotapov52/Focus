import WidgetKit
import SwiftUI

@main
struct TodoWidgetsExtensionBundle: WidgetBundle {
    var body: some Widget {
        TodoWidgetsExtension()
        StatsWidget()
        CalendarWidget()
    }
}
