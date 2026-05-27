import ActivityKit
import OikomiKit
import SwiftUI
import WidgetKit

/// 進行中ワークアウトの Live Activity。
///
/// Lock Screen / Dynamic Island / StandBy で表示。
/// `WorkoutActivityAttributes.ContentState` のフィールド名は触らない（Widget 拡張側で参照のみ）。
struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // watchOS 26 + iOS 26 で Smart Stack ミラー表示に対応するため、@Environment 経由で
            // ActivityFamily を判定し、小サイズ (Watch) と通常 (iOS Lock Screen) を切り替える。
            FamilyAwareLiveActivityContent(context: context)
                // 純正アプリと同様に system material（白っぽい）。`.primary` / `.secondary` を
                // 使うことで Light/Dark の壁紙どちらでも読める。
                .activityBackgroundTint(Color.white.opacity(0.18))
                .activitySystemActionForegroundColor(Color.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                compactLeading(context: context)
            } compactTrailing: {
                compactTrailing(context: context)
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(Color.primary)
            }
            .widgetURL(URL(string: "oikomi://workout"))
            .keylineTint(Color.primary)
        }
        .supplementalActivityFamilies([.small])
    }

    // MARK: - Dynamic Island

    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        HStack(spacing: WidgetSpacing.s) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.primary)
            Text(context.attributes.routineName ?? "ワークアウト")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        Text("\(context.state.setCount) セット")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        let resting = (context.state.restEndAt ?? .distantPast) > .now

        if resting, let endAt = context.state.restEndAt {
            HStack(alignment: .firstTextBaseline, spacing: WidgetSpacing.m) {
                Image(systemName: "timer")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text(endAt, style: .timer)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("レスト残り")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: WidgetSpacing.s) {
                Image(systemName: "timer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(context.attributes.startedAt, style: .timer)
                    .font(.headline.monospacedDigit().weight(.semibold))
                    .lineLimit(1)
                Text("経過")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let name = context.state.currentExerciseName, !name.isEmpty {
                    Spacer(minLength: WidgetSpacing.s)
                    Text(name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func compactLeading(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        Image(systemName: "figure.strengthtraining.traditional")
            .foregroundStyle(Color.primary)
    }

    @ViewBuilder
    private func compactTrailing(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        if let endAt = context.state.restEndAt, endAt > .now {
            Text(endAt, style: .timer)
                .monospacedDigit()
                .foregroundStyle(Color.primary)
                .frame(width: 48)
        } else {
            HStack(spacing: 2) {
                Text("\(context.state.setCount)")
                    .monospacedDigit()
                    .font(.caption.weight(.semibold))
                Image(systemName: "list.bullet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Family-aware content

/// `ActivityFamily` を観測し、Lock Screen (iOS) と Smart Stack (.small / Apple Watch) を切り替える。
/// `.supplementalActivityFamilies([.small])` で Watch ミラーを有効化したため、同じ ContentState を
/// 元に Watch 用の小サイズビューを描画する。
private struct FamilyAwareLiveActivityContent: View {

    let context: ActivityViewContext<WorkoutActivityAttributes>

    @Environment(\.activityFamily) private var activityFamily

    var body: some View {
        switch activityFamily {
        case .small:
            watchSmallBody
        default:
            lockScreenBody
        }
    }

    // MARK: - Shared helpers

    private var isResting: Bool {
        (context.state.restEndAt ?? .distantPast) > .now
    }

    /// "ベンチプレス · 3 セット完了" / "3 セット完了" 形式の 1 行サブタイトル。
    private var subtitleText: String {
        let setLabel = "\(context.state.setCount) セット完了"
        if let name = context.state.currentExerciseName, !name.isEmpty {
            return "\(name) · \(setLabel)"
        }
        return setLabel
    }

    // MARK: - iOS Lock Screen / StandBy

    @ViewBuilder
    private var lockScreenBody: some View {
        VStack(alignment: .leading, spacing: WidgetSpacing.m) {
            HStack(spacing: WidgetSpacing.s) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text(context.attributes.routineName ?? "ワークアウト中")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            Text(subtitleText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            timerRow
        }
        .padding(WidgetSpacing.xl)
    }

    /// レスト中は大型・ブランド色、そうでない時は経過時間を控えめに。
    @ViewBuilder
    private var timerRow: some View {
        if isResting, let endAt = context.state.restEndAt {
            HStack(alignment: .firstTextBaseline, spacing: WidgetSpacing.m) {
                Image(systemName: "timer")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text(endAt, style: .timer)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("レスト残り")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.top, WidgetSpacing.xs)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: WidgetSpacing.s) {
                Image(systemName: "timer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(context.attributes.startedAt, style: .timer)
                    .font(.headline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("経過")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Apple Watch Smart Stack (.small)

    @ViewBuilder
    private var watchSmallBody: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.primary)
                Text(context.attributes.routineName ?? "ワークアウト")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            Text(subtitleText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if isResting, let endAt = context.state.restEndAt {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(endAt, style: .timer)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(context.attributes.startedAt, style: .timer)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .lineLimit(1)
                    Text("経過")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(8)
    }
}
