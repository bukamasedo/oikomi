import OikomiKit
import SwiftData
import SwiftUI

/// 「先月の振り返り」の遷移先。既存サマリがあれば表示、無ければ生成して表示する。
/// 生成はこの画面に来たときだけ走る（ホームでの先読みはしない）。
struct MonthlyRetrospectiveLoaderView: View {
    @Environment(\.modelContext) private var modelContext

    let sessions: [WorkoutSession]
    let sets: [SetRecord]
    let records: [PersonalRecord]
    let snapshots: [HealthSnapshot]
    let bodyPhase: BodyPhaseResult?

    @State private var summary: MonthlySummary?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let summary {
                MonthlySummaryView(summary: summary)
            } else if let errorMessage {
                retryView(errorMessage)
            } else {
                ProgressView("生成中…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(OikomiColor.appBackground)
            }
        }
        .navigationTitle(MonthlySummaryCoordinator.lastMonth())
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        guard summary == nil else { return }
        do {
            summary = try await MonthlySummaryCoordinator.loadOrGenerate(
                context: modelContext, sessions: sessions, sets: sets,
                records: records, snapshots: snapshots, bodyPhase: bodyPhase)
        } catch {
            errorMessage = "生成に失敗しました。時間をおいて再試行してください。"
        }
    }

    @ViewBuilder
    private func retryView(_ message: String) -> some View {
        VStack(spacing: OikomiSpacing.l) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("再試行") {
                errorMessage = nil
                Task { await load() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(OikomiSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OikomiColor.appBackground)
    }
}
