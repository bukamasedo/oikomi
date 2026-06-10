import OikomiKit
import SwiftUI

/// ワークアウト開始前画面のルーティン選択カード。2 列グリッドに並ぶ前提。
struct RoutineCard: View {

    let routine: Routine
    var onStart: () -> Void = {}

    private var exerciseCount: Int { routine.orderedExercises.count }

    private var lastUsedText: String {
        guard let lastUsed = routine.lastUsedAt else { return String(localized: "未実施") }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastUsed, relativeTo: .now)
    }

    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: OikomiSpacing.s) {
                HStack(spacing: OikomiSpacing.xs) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(OikomiColor.brandPrimary)
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(OikomiColor.brandPrimary)
                }

                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(String(localized: "\(exerciseCount) 種目"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(lastUsedText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(OikomiSpacing.l)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(
                OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
