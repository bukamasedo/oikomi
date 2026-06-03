import Foundation

/// 「今日のコンディション」をウィジェットへ受け渡すための App Group 共有スナップショット。
///
/// ウィジェットの TimelineProvider は HealthKit を叩けない（重い・権限）ため、
/// レディネス算出はアプリ本体（`HealthStore.readinessSnapshot()` ＋ `todayValue`）が担い、
/// 結果のみをここに保存してウィジェットが同期読みする。`UnitPreference` と同じ
/// App Group suite (`UserDefaults.sharedAppGroup`) を使う。
///
/// `ReadinessScore` 自体は `Codable` 非対応（Sendable, Hashable のみ）なので、保存用に
/// 値・バンド（rawValue）・データ注記へ展開して持つ。
public struct ConditionSnapshot: Codable, Sendable {
    /// レディネススコア（0-100）。
    public let value: Int
    /// `ReadinessScore.Band.rawValue`。
    public let band: String
    /// `ReadinessScore.Confidence.rawValue`。
    public let confidence: String
    /// 保存時に評価済みのデータソース注記（ウィジェットで再計算しない）。3 信号そろいなら nil。
    public let sourceNote: String?
    /// 今日の HRV（SDNN, ms）。
    public let hrv: Double?
    /// 今日の安静時心拍（bpm）。
    public let restingHeartRate: Double?
    /// 今日の睡眠時間（h）。
    public let sleepHours: Double?
    /// 保存時刻。「今日のものか」を判定する。
    public let savedAt: Date

    public init(
        value: Int,
        band: String,
        confidence: String,
        sourceNote: String?,
        hrv: Double?,
        restingHeartRate: Double?,
        sleepHours: Double?,
        savedAt: Date = Date()
    ) {
        self.value = value
        self.band = band
        self.confidence = confidence
        self.sourceNote = sourceNote
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.sleepHours = sleepHours
        self.savedAt = savedAt
    }

    /// `ReadinessScore` ＋今日値から組み立てる利便イニシャライザ。
    public init(
        readiness: ReadinessScore,
        hrv: Double?,
        restingHeartRate: Double?,
        sleepHours: Double?,
        savedAt: Date = Date()
    ) {
        self.init(
            value: readiness.value,
            band: readiness.band.rawValue,
            confidence: readiness.confidence.rawValue,
            sourceNote: readiness.sourceNote,
            hrv: hrv,
            restingHeartRate: restingHeartRate,
            sleepHours: sleepHours,
            savedAt: savedAt
        )
    }
}

/// `ConditionSnapshot` を App Group 共有 UserDefaults に 1 キー（JSON）で読み書きする。
public enum ConditionSnapshotStore {

    public static let storageKey = "OikomiConditionSnapshot"

    public static func save(_ snapshot: ConditionSnapshot, defaults: UserDefaults = .sharedAppGroup) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }

    /// Pro 解約・権限喪失時など、古いコンディションを残さないために消す。
    public static func clear(defaults: UserDefaults = .sharedAppGroup) {
        defaults.removeObject(forKey: storageKey)
    }

    /// 当日保存されたスナップショットのみ返す。日付がまたいでいれば nil（ウィジェットはプレースホルダ表示）。
    public static func todaySnapshot(
        referenceDate: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults = .sharedAppGroup
    ) -> ConditionSnapshot? {
        guard let data = defaults.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(ConditionSnapshot.self, from: data),
            calendar.isDate(snapshot.savedAt, inSameDayAs: referenceDate)
        else {
            return nil
        }
        return snapshot
    }
}
