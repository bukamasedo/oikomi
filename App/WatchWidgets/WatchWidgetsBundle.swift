import SwiftUI
import WidgetKit

/// watchOS 用の WidgetBundle。Apple Watch の Smart Stack / Complication として登録される。
///
/// 仕様書 §8.3「Complication / Smart Stack 表示」。iOS の `OikomiWidgetsBundle` と
/// 同じ `StatsWidget` を共有しているが、Live Activity 系は iOS のみのため除外。
@main
struct WatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        StatsWidget()
    }
}
