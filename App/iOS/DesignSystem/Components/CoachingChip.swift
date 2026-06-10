import OikomiKit
import SwiftUI

/// AI コーチング助言を 1 件表現するチップ。
/// severity に応じて色とアイコンを切り替え、横並びの ScrollView に並べる前提。
struct CoachingChip: View {

    let advice: CoachingAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            HStack(spacing: OikomiSpacing.xs) {
                Image(systemName: iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(severityColor)
                Text(severityLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(severityColor)
                    .textCase(.uppercase)
            }

            Text(advice.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(advice.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(OikomiSpacing.l)
        .frame(width: 260, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .stroke(severityColor.opacity(0.25), lineWidth: 1)
        )
    }

    private var iconName: String {
        switch advice.severity {
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.seal.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch advice.severity {
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
    }

    private var severityLabel: String {
        switch advice.severity {
        case .warning: return String(localized: "注意")
        case .success: return String(localized: "好調")
        case .info: return String(localized: "情報")
        }
    }
}

#Preview("Light") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: OikomiSpacing.m) {
            CoachingChip(
                advice: CoachingAdvice(
                    title: "胸のディロード推奨",
                    message: "胸ボリュームが MAV を超過しています。今週は -30% を検討してください。",
                    severity: .warning,
                    impact: 1000
                )
            )
            CoachingChip(
                advice: CoachingAdvice(
                    title: "PR 予測: ベンチプレス",
                    message: "推定1RM が安定して伸びています。85kg × 3 が狙えるかも。",
                    severity: .info,
                    impact: 500
                )
            )
        }
        .padding()
    }
    .background(OikomiColor.appBackground)
}

#Preview("Dark") {
    HStack {
        CoachingChip(
            advice: CoachingAdvice(
                title: "順調なボリューム",
                message: "脚ボリュームが MEV を維持できています。",
                severity: .success,
                impact: 200
            )
        )
    }
    .padding()
    .background(OikomiColor.appBackground)
    .preferredColorScheme(.dark)
}
