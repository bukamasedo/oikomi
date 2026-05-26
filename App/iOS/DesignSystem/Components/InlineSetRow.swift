import OikomiKit
import SwiftUI

/// セッション中の 1 セット行を表示するインラインセル。Apple リマインダー風。
///
/// - 左端: 完了チェックマーク（タップで markSetCompleted を呼ぶ想定）
/// - 中央: 「(順番)  重量 × レップ」または「(順番) Xレップ（自重）」
/// - 右端: 未完了は実施予定のレスト時間（⏱90秒）/ 完了は推定 1RM
struct InlineSetRow: View {

    let set: SetRecord
    let indexInGroup: Int
    var onToggleComplete: (() -> Void)? = nil
    /// 重量・レップ部分をタップしたとき呼ばれる。編集シート起動用。nil なら無反応。
    var onEditTap: (() -> Void)? = nil

    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? UnitPreference.defaultUnit
    }

    var body: some View {
        HStack(spacing: OikomiSpacing.m) {
            Button {
                onToggleComplete?()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
                    .symbolEffect(.bounce, value: set.isCompleted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.isCompleted ? "完了済み。タップで未完了に戻す" : "未完了。タップで完了")

            // 値部分のタップで編集起動。チェックマークと領域を分離することで、
            // 「ワンタップで完了」と「値を編集」を視覚的に区別する。
            Button {
                onEditTap?()
            } label: {
                HStack(spacing: OikomiSpacing.m) {
                    Text("\(indexInGroup)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 18, alignment: .leading)

                    valueLabel
                        .foregroundStyle(set.isCompleted ? .secondary : .primary)

                    Spacer(minLength: OikomiSpacing.s)

                    trailingAccessory
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onEditTap == nil)
            .accessibilityLabel("セット \(indexInGroup) を編集")
        }
        .padding(.vertical, OikomiSpacing.s)
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if set.isCompleted {
            if let rm = set.estimated1RM {
                Text("1RM \(rm.formatted(.number.precision(.fractionLength(0))))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        } else {
            let rest = set.resolveRestSeconds()
            if rest > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "timer")
                    Text("\(rest)秒")
                        .monospacedDigit()
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var valueLabel: some View {
        if let weight = set.weight, let reps = set.reps {
            Text("\(WeightFormatter.string(kilograms: weight, in: weightUnit)) × \(reps)")
                .font(OikomiFont.setValue)
        } else if let reps = set.reps {
            Text("\(reps) レップ（自重）")
                .font(OikomiFont.setValue)
        } else {
            Text("—")
                .font(OikomiFont.setValue)
                .foregroundStyle(.secondary)
        }
    }
}
