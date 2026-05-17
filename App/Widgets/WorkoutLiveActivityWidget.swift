import ActivityKit
import SwiftUI
import WidgetKit
import OikomiKit

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / Banner
            lockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.65))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.routineName ?? "ワークアウト")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(context.attributes.startedAt, style: .timer)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.setCount)")
                            .font(.title3.monospacedDigit().weight(.semibold))
                        Text("セット")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let endAt = context.state.restEndAt, endAt > .now {
                        HStack {
                            Image(systemName: "timer")
                            Text("レスト")
                            Spacer()
                            Text(endAt, style: .timer)
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    } else if let name = context.state.currentExerciseName {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                            Text(name)
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                    }
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.tint)
            } compactTrailing: {
                if let endAt = context.state.restEndAt, endAt > .now {
                    Text(endAt, style: .timer)
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                        .frame(width: 44)
                } else {
                    Text("\(context.state.setCount)")
                        .monospacedDigit()
                }
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.tint)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.tint)
                Text(context.attributes.routineName ?? "ワークアウト中")
                    .font(.headline)
                Spacer()
                Text(context.attributes.startedAt, style: .timer)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("セット数")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(context.state.setCount)")
                        .font(.title2.monospacedDigit().weight(.semibold))
                }

                if let endAt = context.state.restEndAt, endAt > .now {
                    Divider()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("レスト残り")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(endAt, style: .timer)
                            .font(.title2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }

                if let name = context.state.currentExerciseName, context.state.restEndAt == nil {
                    Divider()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("直近")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
        }
        .padding()
    }
}
