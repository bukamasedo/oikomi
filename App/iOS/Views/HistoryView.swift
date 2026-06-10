import OikomiKit
import SwiftData
import SwiftUI

/// 履歴タブ。Apple Fitness History + ヘルスケアの期間セグメントに着想を得た構成。
struct HistoryView: View {

    @Query(
        filter: #Predicate<WorkoutSession> { $0.endedAt != nil },
        sort: \WorkoutSession.startedAt,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    @State private var selectedDate: Date?
    @State private var navigationTarget: WorkoutSession?

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    private let calendar = Calendar.current

    private var activeDates: Set<Date> {
        Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
    }

    private var periodSessions: [WorkoutSession] {
        if let selectedDate {
            return sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: selectedDate) }
        }
        guard let interval = periodInterval else { return sessions }
        return sessions.filter { interval.contains($0.startedAt) }
    }

    // 集計は「今週」固定（直近基準）。日付を選べばその日に切り替わる。
    private var periodInterval: DateInterval? {
        calendar.dateInterval(of: .weekOfYear, for: Date())
    }

    private var totalSets: Int {
        periodSessions.reduce(0) { $0 + ($1.sets?.count ?? 0) }
    }

    private var totalVolume: Double {
        periodSessions
            .flatMap { $0.sets ?? [] }
            .filter(\.isCompleted)
            .reduce(0) { acc, s in
                guard let w = s.weight, let r = s.reps else { return acc }
                return acc + w * Double(r)
            }
    }

    // 通算（全期間）。スコープ(週/月)に依存しないので sessions 全体から集計する。
    private var allTimeVolume: Double {
        sessions
            .flatMap { $0.sets ?? [] }
            .filter(\.isCompleted)
            .reduce(0) { acc, s in
                guard let w = s.weight, let r = s.reps else { return acc }
                return acc + w * Double(r)
            }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    summaryCard
                }
                .listRowBackground(Color.clear)
                .listRowInsets(
                    EdgeInsets(
                        top: OikomiSpacing.l, leading: OikomiSpacing.l,
                        bottom: 0, trailing: OikomiSpacing.l)
                )
                .listRowSeparator(.hidden)

                Section {
                    HistoryCalendarView(activeDates: activeDates, selectedDate: $selectedDate)
                        .padding(OikomiSpacing.l)
                        .background(
                            OikomiColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
                }
                .listRowBackground(Color.clear)
                .listRowInsets(
                    EdgeInsets(
                        top: OikomiSpacing.l, leading: OikomiSpacing.l,
                        bottom: 0, trailing: OikomiSpacing.l)
                )
                .listRowSeparator(.hidden)

                if periodSessions.isEmpty {
                    Section {
                        OikomiEmptyState(
                            title: String(localized: "この期間の記録はありません"),
                            message: String(localized: "カレンダーで別の日付を選んでください。"),
                            systemImage: "calendar.badge.exclamationmark",
                            tint: OikomiColor.brandPrimary
                        )
                        .frame(minHeight: 200)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(
                        EdgeInsets(
                            top: OikomiSpacing.l, leading: OikomiSpacing.l,
                            bottom: OikomiSpacing.xxl, trailing: OikomiSpacing.l)
                    )
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        sessionsCard
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(
                        EdgeInsets(
                            top: OikomiSpacing.l, leading: OikomiSpacing.l,
                            bottom: OikomiSpacing.xxl, trailing: OikomiSpacing.l)
                    )
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            // List 既定のセクション余白を消し、カード間・先頭余白を listRowInsets だけで
            // 制御する(ホーム/トレーニングの ScrollView と同じ 16pt スケールに揃えるため)。
            .listSectionSpacing(0)
            .scrollContentBackground(.hidden)
            .background(OikomiColor.appBackground)
            .navigationTitle("履歴")
            .navigationDestination(item: $navigationTarget) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var sessionsSectionTitle: String {
        if let selectedDate {
            return selectedDate.formatted(.dateTime.year().month(.abbreviated).day())
                + String(localized: " のセッション")
        }
        return String(localized: "今週のセッション (\(periodSessions.count))")
    }

    // 見出しはカード外ではなくカード内に置き、全セッションを 1 枚のカードにまとめる
    //（ホームの「直近の自己ベスト」カードと同じ構成）。
    @ViewBuilder
    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Label(sessionsSectionTitle, systemImage: "figure.strengthtraining.traditional")
                    .font(.subheadline.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.primary)
                Spacer(minLength: OikomiSpacing.s)
                if selectedDate != nil {
                    Button("すべて") { selectedDate = nil }
                        .font(.subheadline.weight(.medium))
                }
            }

            ForEach(Array(periodSessions.enumerated()), id: \.element.id) { index, session in
                if index > 0 {
                    Divider()
                }
                Button {
                    navigationTarget = session
                } label: {
                    WorkoutHistoryRow(session: session)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
    }

    @ViewBuilder
    private var summaryCard: some View {
        VStack(spacing: OikomiSpacing.m) {
            HStack(spacing: OikomiSpacing.m) {
                summaryTile(
                    title: String(localized: "セッション"),
                    value: "\(periodSessions.count)",
                    unit: String(localized: "回"),
                    systemImage: "figure.strengthtraining.traditional",
                    tint: OikomiColor.brandPrimary
                )
                divider
                summaryTile(
                    title: String(localized: "セット"),
                    value: "\(totalSets)",
                    unit: "",
                    systemImage: "list.bullet",
                    tint: OikomiColor.statBlue
                )
                divider
                summaryTile(
                    title: String(localized: "ボリューム"),
                    value: WeightFormatter.numberOnly(
                        kilograms: totalVolume, in: weightUnit, fractionDigits: 0...0),
                    unit: weightUnit.symbol,
                    systemImage: "scalemass.fill",
                    tint: OikomiColor.statIndigo
                )
            }

            Divider()
                .overlay(OikomiColor.separator)

            // 通算（全期間）。週/月トグルに依存しない不変の積み上げを 1 行で示す。
            HStack(spacing: OikomiSpacing.xs) {
                Image(systemName: "infinity")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(
                    String(localized: "通算 \(sessions.count)回・")
                        + WeightFormatter.numberOnly(
                            kilograms: allTimeVolume, in: weightUnit, fractionDigits: 0...0)
                        + weightUnit.symbol
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private func summaryTile(
        title: String, value: String, unit: String, systemImage: String, tint: Color
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(OikomiFont.statValueCompact)
                if !unit.isEmpty {
                    Text(unit)
                        .font(OikomiFont.metricUnit)
                        .foregroundStyle(.secondary)
                }
            }
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(OikomiColor.separator)
            .frame(width: 1)
            .padding(.vertical, OikomiSpacing.xs)
    }
}

#Preview("Light") {
    HistoryView()
        .modelContainer(
            for: [
                WorkoutSession.self, SetRecord.self, Exercise.self, Routine.self,
                RoutineExercise.self, PersonalRecord.self, HealthSnapshot.self,
            ], inMemory: true)
}

#Preview("Dark") {
    HistoryView()
        .modelContainer(
            for: [
                WorkoutSession.self, SetRecord.self, Exercise.self, Routine.self,
                RoutineExercise.self, PersonalRecord.self, HealthSnapshot.self,
            ], inMemory: true
        )
        .preferredColorScheme(.dark)
}
