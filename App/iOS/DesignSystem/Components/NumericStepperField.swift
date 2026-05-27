import OikomiKit
import SwiftUI

/// 大型 ±入力フィールド。AddSetSheet の重量・レップ入力に使う。
///
/// - 単タップで step 1 単位の増減。
/// - 長押し中は加速度的に連続増減（300ms ごとに 1 ティック、最大 50ms まで加速）。
/// - 直前値からの差分を `delta` で渡すと右上にバッジ表示する。
struct NumericStepperField: View {

    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    /// 表示時のフォーマッタ。デフォルトは小数 1 桁。
    var formatter: (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0...1))) }
    var unit: String = ""
    /// 直前値との差分。nil なら表示しない。
    var delta: Double? = nil

    @State private var holdTask: Task<Void, Never>? = nil
    @State private var holdInterval: Double = 0.3
    @State private var pressedSymbol: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let delta {
                    deltaBadge(delta)
                }
            }

            HStack(spacing: OikomiSpacing.l) {
                stepperButton(systemImage: "minus") { tick(by: -step) }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatter(value))
                        .font(.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText(value: value))
                        .animation(.snappy, value: value)
                        .accessibilityLabel("\(title) \(formatter(value)) \(unit)")
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                stepperButton(systemImage: "plus") { tick(by: step) }
            }
        }
        .padding(OikomiSpacing.l)
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private func stepperButton(systemImage: String, action: @escaping () -> Void) -> some View {
        // Button + simultaneousGesture(LongPressGesture) は SwiftUI の競合解決でタップが
        // 抑制されることがあるため、Image + onTapGesture + onLongPressGesture(onPressingChanged:)
        // の組み合わせに分けて、単タップと長押し連続加減を確実に両立させる。
        let isPressed = pressedSymbol == systemImage
        Image(systemName: systemImage)
            .font(.title2.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 56, height: 56)
            .background(Circle().fill(OikomiColor.elevatedBackground))
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
            .contentShape(Circle())
            .onTapGesture {
                action()
            }
            .onLongPressGesture(
                minimumDuration: 0.4,
                maximumDistance: 60,
                perform: {
                    startContinuousTick(action: action)
                },
                onPressingChanged: { pressing in
                    pressedSymbol = pressing ? systemImage : nil
                    if !pressing {
                        stopContinuousTick()
                    }
                }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(systemImage.contains("plus") ? "増やす" : "減らす")
            .onDisappear { stopContinuousTick() }
    }

    private func tick(by delta: Double) {
        let newValue = (value + delta).clamped(to: range)
        // 単位丸め（step の整数倍にする）
        let rounded = (newValue / step).rounded() * step
        value = rounded
    }

    private func startContinuousTick(action: @escaping () -> Void) {
        stopContinuousTick()
        holdInterval = 0.3
        holdTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(holdInterval))
                if Task.isCancelled { break }
                action()
                holdInterval = max(0.05, holdInterval * 0.85)
            }
        }
    }

    private func stopContinuousTick() {
        holdTask?.cancel()
        holdTask = nil
    }

    @ViewBuilder
    private func deltaBadge(_ d: Double) -> some View {
        let sign: String = d > 0 ? "+" : (d < 0 ? "" : "±")
        let color: Color = d > 0 ? .green : (d < 0 ? .red : .secondary)
        let text = sign + formatter(d)
        HStack(spacing: 2) {
            Image(systemName: d > 0 ? "arrow.up" : (d < 0 ? "arrow.down" : "equal"))
            Text("前回 " + text)
        }
        .font(OikomiFont.metaEmphasized)
        .foregroundStyle(color)
        .padding(.horizontal, OikomiSpacing.s)
        .padding(.vertical, 2)
        .background(color.opacity(0.12), in: Capsule())
    }
}

extension Comparable {
    fileprivate func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

/// 重量専用の ± 入力フィールド。
///
/// 内部 Binding は常に kg。表示・操作はユーザー設定の `WeightUnit`（kg / lb）で行い、
/// 値の読み書き時に自動変換する。`NumericStepperField` の薄いラッパー。
struct WeightStepperField: View {

    let title: String
    @Binding var kilograms: Double
    let unit: WeightUnit
    /// nil の場合は `unit.defaultRange` を使う（kg: 0...500 / lb: 0...1100）。
    var rangeInKilograms: ClosedRange<Double>? = nil
    /// 直前値との差分（kg）。nil なら表示しない。
    var deltaKilograms: Double? = nil

    var body: some View {
        let displayBinding = Binding<Double>(
            get: { unit.fromKilograms(kilograms) },
            set: { newDisplay in kilograms = unit.toKilograms(newDisplay) }
        )
        let displayRange: ClosedRange<Double> = {
            guard let r = rangeInKilograms else { return unit.defaultRange }
            return unit.fromKilograms(r.lowerBound)...unit.fromKilograms(r.upperBound)
        }()
        let displayDelta = deltaKilograms.map { unit.fromKilograms($0) }

        NumericStepperField(
            title: title,
            value: displayBinding,
            range: displayRange,
            step: unit.displayStep,
            unit: unit.symbol,
            delta: displayDelta
        )
    }
}

#Preview("Light") {
    StatefulPreviewWrapper(50.0) { weight in
        VStack(spacing: OikomiSpacing.l) {
            WeightStepperField(
                title: "重量",
                kilograms: weight,
                unit: .kg,
                deltaKilograms: 5.0
            )
            StatefulPreviewWrapper(8.0) { reps in
                NumericStepperField(
                    title: "レップ",
                    value: reps,
                    range: 1...100,
                    step: 1,
                    formatter: { "\(Int($0))" },
                    unit: "回",
                    delta: 0
                )
            }
        }
        .padding()
        .background(OikomiColor.appBackground)
    }
}

#Preview("Pounds") {
    StatefulPreviewWrapper(50.0) { weight in
        WeightStepperField(
            title: "重量",
            kilograms: weight,
            unit: .lb,
            deltaKilograms: -2.5
        )
        .padding()
        .background(OikomiColor.appBackground)
        .preferredColorScheme(.dark)
    }
}
