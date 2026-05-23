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
            lockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.65))
                .activitySystemActionForegroundColor(.white)
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
                    .foregroundStyle(WidgetColor.brand)
            }
            .widgetURL(URL(string: "oikomi://workout"))
            .keylineTint(WidgetColor.brand)
        }
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private func lockScreenView(
        context: ActivityViewContext<WorkoutActivityAttributes>
    ) -> some View {
        VStack(alignment: .leading, spacing: WidgetSpacing.l) {
            // Header: ブランドカラーのアイコンチップ + ルーティン名 + 経過時間
            HStack(spacing: WidgetSpacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: WidgetRadius.tile, style: .continuous)
                        .fill(WidgetColor.brand.opacity(0.25))
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(WidgetColor.brand)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 0) {
                    Text(context.attributes.routineName ?? "ワークアウト中")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("Oikomi セッション")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text(context.attributes.startedAt, style: .timer)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.white)
                    Text("経過")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Body: セット数 + レスト残り or 直近種目
            if let endAt = context.state.restEndAt, endAt > .now {
                restingBody(endAt: endAt, setCount: context.state.setCount)
            } else {
                idleBody(
                    setCount: context.state.setCount,
                    currentExerciseName: context.state.currentExerciseName)
            }
        }
        .padding(WidgetSpacing.xl)
    }

    @ViewBuilder
    private func restingBody(endAt: Date, setCount: Int) -> some View {
        HStack(alignment: .center, spacing: WidgetSpacing.l) {
            VStack(alignment: .leading, spacing: 1) {
                Text("セット")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(setCount)")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            .fixedSize(horizontal: true, vertical: false)

            Divider()
                .overlay(Color.white.opacity(0.2))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text("レスト残り")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(WidgetColor.brand)

                Text(endAt, style: .timer)
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(WidgetColor.brand)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)

            Spacer()
        }
    }

    @ViewBuilder
    private func idleBody(setCount: Int, currentExerciseName: String?) -> some View {
        HStack(alignment: .center, spacing: WidgetSpacing.l) {
            VStack(alignment: .leading, spacing: 1) {
                Text("セット")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(setCount)")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            .fixedSize(horizontal: true, vertical: false)

            if let name = currentExerciseName {
                Divider()
                    .overlay(Color.white.opacity(0.2))
                VStack(alignment: .leading, spacing: 1) {
                    Text("直近")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
    }

    // MARK: - Dynamic Island

    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WidgetColor.brand)
                Text(context.attributes.routineName ?? "ワークアウト")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            Text(context.attributes.startedAt, style: .timer)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        VStack(alignment: .trailing, spacing: 0) {
            Text("\(context.state.setCount)")
                .font(.title3.monospacedDigit().weight(.bold))
            Text("セット")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        if let endAt = context.state.restEndAt, endAt > .now {
            HStack(spacing: WidgetSpacing.m) {
                Image(systemName: "timer")
                    .font(.subheadline.weight(.semibold))
                Text("レスト")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(endAt, style: .timer)
                    .font(.subheadline.monospacedDigit().weight(.bold))
            }
            .foregroundStyle(WidgetColor.brand)
            .padding(.horizontal, WidgetSpacing.s)
            .padding(.vertical, WidgetSpacing.s)
            .background(
                WidgetColor.brand.opacity(0.15),
                in: RoundedRectangle(cornerRadius: WidgetRadius.chip, style: .continuous)
            )
        } else if let name = context.state.currentExerciseName {
            HStack(spacing: WidgetSpacing.s) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.subheadline)
                    .foregroundStyle(WidgetColor.brand)
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func compactLeading(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        Image(systemName: "figure.strengthtraining.traditional")
            .foregroundStyle(WidgetColor.brand)
    }

    @ViewBuilder
    private func compactTrailing(context: ActivityViewContext<WorkoutActivityAttributes>)
        -> some View
    {
        if let endAt = context.state.restEndAt, endAt > .now {
            Text(endAt, style: .timer)
                .monospacedDigit()
                .foregroundStyle(WidgetColor.brand)
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
