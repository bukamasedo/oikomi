import Foundation

/// HRV・睡眠・安静時心拍を統合した「今日のコンディション（レディネス）」スコア。
///
/// すべて純粋関数。HealthKit I/O は持たず、`[HealthTrendPoint]` 系列と今日の睡眠時間を入力に取る。
/// Apple Watch 無し等で信号が欠ける場合は、利用可能な信号だけで重みを再配分して算出する（nil を 0 扱いしない）。
public struct ReadinessScore: Sendable, Hashable {

    public enum Band: String, Sendable { case low, normal, high }
    public enum Confidence: String, Sendable { case low, medium, high }
    public enum Signal: String, Sendable { case hrv, restingHeartRate, sleep }

    /// 0〜100。利用可能な信号のみで算出。
    public let value: Int
    public let band: Band
    public let confidence: Confidence
    /// HRV の z-score（将来の自然言語サマリ用・デバッグ用）。HRV 不使用時は nil。
    public let hrvZ: Double?
    public let usedSignals: [Signal]

    public init(value: Int, band: Band, confidence: Confidence, hrvZ: Double?, usedSignals: [Signal]) {
        self.value = value
        self.band = band
        self.confidence = confidence
        self.hrvZ = hrvZ
        self.usedSignals = usedSignals
    }

    /// UI に出すデータソース注記。3 信号そろい（confidence == .high）なら nil。
    public var sourceNote: String? {
        guard confidence != .high else { return nil }
        if usedSignals.isEmpty { return nil }
        // HRV も安静時心拍も無い＝ Apple Watch 由来データが一切無い場合のみ「未接続」と断定する。
        // 安静時心拍だけある場合は Watch は繋がっており HRV 履歴が足りないだけなので汎用文にフォールバック。
        if !usedSignals.contains(.hrv) && !usedSignals.contains(.restingHeartRate) {
            return "Apple Watch 未接続のため、利用可能なデータで算出しています。"
        }
        return "一部のデータが不足しているため、参考値です。"
    }

    // MARK: - 計算

    /// スコア値からバンドを決める。compute() と月次集計で共有する。
    public static func band(for value: Int) -> Band {
        value < 40 ? .low : (value < 70 ? .normal : .high)
    }

    /// 重み（HRV 主）。将来 goal 別に差し替え可能なよう定数化。
    static let hrvWeight = 0.5
    static let sleepWeight = 0.3
    static let rhrWeight = 0.2

    /// レディネススコアを算出する。算出に使える信号が 1 つも無ければ nil。
    public static func compute(
        hrvSeries: [HealthTrendPoint],
        rhrSeries: [HealthTrendPoint],
        sleepHours: Double?,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ReadinessScore? {
        var subscores: [(signal: Signal, score: Double, weight: Double)] = []
        var hrvZValue: Double?

        // HRV: 高いほど良い
        if let z = zScore(series: hrvSeries) {
            hrvZValue = z
            subscores.append((.hrv, scoreFromZ(z), hrvWeight))
        }
        // 安静時心拍: 高いほど悪い → z を反転
        if let z = zScore(series: rhrSeries) {
            subscores.append((.restingHeartRate, scoreFromZ(-z), rhrWeight))
        }
        // 睡眠: 8h = 80 を基準に正規化（10h で 100 にキャップ）。0h は「データ無し」とみなし除外する。
        if let hours = sleepHours, hours > 0 {
            let s = min(min(hours / 8.0, 1.25) * 80.0, 100.0)
            subscores.append((.sleep, s, sleepWeight))
        }

        guard !subscores.isEmpty else { return nil }

        let totalWeight = subscores.reduce(0) { $0 + $1.weight }
        let weighted = subscores.reduce(0) { $0 + $1.score * $1.weight } / totalWeight
        let value = Int(weighted.rounded())

        // 暫定閾値（テストで調整可）
        let band = Self.band(for: value)
        let confidence: Confidence =
            subscores.count >= 3 ? .high : (subscores.count == 2 ? .medium : .low)

        return ReadinessScore(
            value: value,
            band: band,
            confidence: confidence,
            hrvZ: hrvZValue,
            usedSignals: subscores.map(\.signal)
        )
    }

    /// 系列の「最新値 vs それ以前のベースライン」の z-score。
    /// 有効サンプル（value > 0）が 14 件未満、または SD が 0 のときは nil。
    static func zScore(series: [HealthTrendPoint]) -> Double? {
        let valid = series.filter { $0.value > 0 }.sorted { $0.date < $1.date }
        // 14 件以上で、最新を today、それ以前（≥13 件）をベースラインとする。
        guard valid.count >= 14, let today = valid.last?.value else { return nil }
        let baseline = valid.dropLast().map(\.value)
        let mean = baseline.reduce(0, +) / Double(baseline.count)
        // 母集団からの標本なので不偏分散（N-1 / ベッセル補正）を使う。HRV ガイドの標準。
        let variance =
            baseline.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(baseline.count - 1)
        let sd = variance.squareRoot()
        guard sd > 0 else { return nil }
        return (today - mean) / sd
    }

    /// z-score を 0〜100 のサブスコアにマップ（z=0 → 50、z=±2 → 90/10、クランプ）。
    static func scoreFromZ(_ z: Double) -> Double {
        min(max(50.0 + z * 20.0, 0.0), 100.0)
    }
}
