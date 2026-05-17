import SwiftUI
import WidgetKit

@main
struct OikomiWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
        StatsWidget()
    }
}
