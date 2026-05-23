import Foundation

/// HealthKit 由来の日次トレンドデータの 1 ポイント。
///
/// HRV / 安静時心拍 / 睡眠時間 / 体重 / 体脂肪率 / LBM などの
/// 推移グラフ用の汎用値型。SwiftData には保存せず、表示時に都度クエリする。
public struct HealthTrendPoint: Sendable, Identifiable, Hashable {
    public var id: Date { date }
    public let date: Date
    public let value: Double

    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}
