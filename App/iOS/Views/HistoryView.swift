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

    @State private var period: PeriodSegment.Period = .week
    @State private var selectedDate: Date?

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

    private var periodInterval: DateInterval? {
        let now = Date()
        switch period {
        case .day:
            return calendar.dateInterval(of: .day, for: now)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)
        case .month:
            return calendar.dateInterval(of: .month, for: now)
        case .year:
            return calendar.dateInterval(of: .year, for: now)
        case .all:
            return nil
        }
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: OikomiSpacing.l) {
                    PeriodSegment(selection: $period)

                    summaryCard

                    HistoryCalendarView(activeDates: activeDates, selectedDate: $selectedDate)
                        .padding(OikomiSpacing.l)
                        .background(
                            OikomiColor.cardBackground,
                            in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))

                    if periodSessions.isEmpty {
                        OikomiEmptyState(
                            title: "この期間の記録はありません",
                            message: "期間を切り替えるか、カレンダーで別の日付を選んでください。",
                            systemImage: "calendar.badge.exclamationmark",
                            tint: OikomiColor.brandPrimary
                        )
                        .frame(minHeight: 200)
                    } else {
                        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
                            SectionHeader(
                                title: sessionsSectionTitle,
                                trailing: {
                                    if selectedDate != nil {
                                        Button("すべて") { selectedDate = nil }
                                            .font(.subheadline.weight(.medium))
                                    }
                                }
                            )
                            VStack(spacing: OikomiSpacing.m) {
                                ForEach(periodSessions) { session in
                                    NavigationLink(value: session) {
                                        WorkoutHistoryCard(session: session)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.bottom, OikomiSpacing.xxl)
            }
            .background(OikomiColor.appBackground)
            .navigationTitle("履歴")
            .navigationDestination(for: WorkoutSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var sessionsSectionTitle: String {
        if let selectedDate {
            return selectedDate.formatted(.dateTime.year().month(.abbreviated).day()) + " のセッション"
        }
        switch period {
        case .day: return "今日のセッション"
        case .week: return "今週のセッション (\(periodSessions.count))"
        case .month: return "今月のセッション (\(periodSessions.count))"
        case .year: return "今年のセッション (\(periodSessions.count))"
        case .all: return "全セッション (\(periodSessions.count))"
        }
    }

    @ViewBuilder
    private var summaryCard: some View {
        HStack(spacing: OikomiSpacing.m) {
            summaryTile(
                title: "セッション",
                value: "\(periodSessions.count)",
                unit: "回",
                systemImage: "figure.strengthtraining.traditional",
                tint: OikomiColor.brandPrimary
            )
            divider
            summaryTile(
                title: "セット",
                value: "\(totalSets)",
                unit: "",
                systemImage: "list.bullet",
                tint: OikomiColor.statBlue
            )
            divider
            summaryTile(
                title: "ボリューム",
                value: WeightFormatter.numberOnly(
                    kilograms: totalVolume, in: weightUnit, fractionDigits: 0...0),
                unit: weightUnit.symbol,
                systemImage: "scalemass.fill",
                tint: OikomiColor.statIndigo
            )
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
