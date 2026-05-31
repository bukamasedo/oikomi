import OikomiKit
import SwiftData
import SwiftUI

/// 過去の月次振り返りを新しい順に並べる一覧。
struct MonthlySummaryHistoryView: View {
    @Query(sort: \MonthlySummary.generatedAt, order: .reverse)
    private var summaries: [MonthlySummary]

    var body: some View {
        ScrollView {
            VStack(spacing: OikomiSpacing.m) {
                if summaries.isEmpty {
                    Text("まだ振り返りがありません。月初に先月分が生成されます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OikomiSpacing.xxl)
                } else {
                    ForEach(summaries) { summary in
                        NavigationLink {
                            MonthlySummaryView(summary: summary)
                        } label: {
                            VStack(alignment: .leading, spacing: OikomiSpacing.xs) {
                                Text(summary.yearMonth)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(summary.headline)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(OikomiSpacing.l)
                            .background(
                                OikomiColor.cardBackground,
                                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.bottom, OikomiSpacing.xxl)
        }
        .scrollContentBackground(.hidden)
        .background(OikomiColor.appBackground)
        .navigationTitle("振り返り履歴")
    }
}
