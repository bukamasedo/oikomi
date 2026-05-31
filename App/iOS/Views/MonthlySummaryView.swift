import OikomiKit
import SwiftUI

/// 1 か月分の振り返りを表示する詳細画面。
struct MonthlySummaryView: View {
    let summary: MonthlySummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OikomiSpacing.l) {
                Text(summary.headline)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(OikomiSpacing.l)
                    .background(
                        OikomiColor.cardBackground,
                        in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))

                section(
                    title: "ハイライト", systemImage: "star.fill", tint: OikomiColor.statGreen,
                    items: summary.highlights)
                section(
                    title: "気になる点", systemImage: "exclamationmark.triangle.fill",
                    tint: OikomiColor.statOrange, items: summary.watchPoints)
                section(
                    title: "来月のフォーカス", systemImage: "target", tint: OikomiColor.statBlue,
                    items: summary.nextFocus)
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.bottom, OikomiSpacing.xxl)
        }
        .scrollContentBackground(.hidden)
        .background(OikomiColor.appBackground)
        .navigationTitle(summary.yearMonth)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(title: String, systemImage: String, tint: Color, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: OikomiSpacing.m) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: OikomiSpacing.s) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(tint)
                            .padding(.top, 6)
                        Text(item)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(OikomiSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                OikomiColor.cardBackground,
                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
        }
    }
}
