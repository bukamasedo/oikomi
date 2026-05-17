import Foundation

/// 1RM（最大挙上重量）推定の純粋関数群。
///
/// 数式ベースでオンデバイス完結。仕様書 §4.2.3 / §5.3 参照。
public enum OneRepMax {

    /// Epley 式: 1RM = weight × (1 + reps / 30)
    ///
    /// レップ数が比較的少ない（1〜10）範囲で精度が高く、業界標準的に使われる。
    public static func epley(weight: Double, reps: Int) -> Double {
        guard reps >= 1, weight > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }

    /// Brzycki 式: 1RM = weight × 36 / (37 - reps)
    ///
    /// レップ数が 10 を超える場合は精度が落ちる。
    public static func brzycki(weight: Double, reps: Int) -> Double {
        guard reps >= 1, weight > 0, reps < 37 else { return 0 }
        return weight * 36.0 / (37.0 - Double(reps))
    }

    /// セッション内のセットから最大の推定 1RM を返す。
    ///
    /// - Parameter sets: `(weight, reps)` のタプル配列
    /// - Returns: 最大の推定 1RM。空なら 0
    public static func best(from sets: [(weight: Double, reps: Int)]) -> Double {
        sets.map { epley(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

    /// 推定 1RM に対する相対強度（%1RM）。
    public static func relativeIntensity(weight: Double, estimated1RM: Double) -> Double {
        guard estimated1RM > 0 else { return 0 }
        return weight / estimated1RM
    }
}
