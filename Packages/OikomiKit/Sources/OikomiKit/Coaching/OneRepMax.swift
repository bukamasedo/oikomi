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

    /// レップ域に応じた式選択 + RIR 補正つきの 1RM 推定。
    ///
    /// - RIR 補正: 実効レップ = reps + (10 - rpe)。RPE8(RIR2) のセットは「あと2レップ可能」とみなす。
    ///   rpe が nil のときは reps をそのまま使う（既存挙動互換）。
    /// - 式選択: 実効レップ 1〜5 → Epley、6 以上 → Brzycki（高レップで精度が落ちる Epley を避ける）。
    ///
    /// RPE は定義域 [1, 10]。範囲外の入力は丸めて扱う（epley/brzycki が weight を guard するのと同じ防御）。
    public static func estimate(weight: Double, reps: Int, rpe: Double?) -> Double {
        guard reps >= 1, weight > 0 else { return 0 }
        let rir = rpe.map { Int((10.0 - min(max($0, 1.0), 10.0)).rounded()) } ?? 0
        let effectiveReps = max(1, reps + max(0, rir))
        if effectiveReps <= 5 {
            return epley(weight: weight, reps: effectiveReps)
        }
        return brzycki(weight: weight, reps: effectiveReps)
    }
}
