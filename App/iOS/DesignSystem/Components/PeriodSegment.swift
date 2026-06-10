import SwiftUI

/// Apple ヘルスケアの D / W / M / Y / All 期間セグメント。
struct PeriodSegment: View {

    enum Period: String, CaseIterable, Identifiable {
        case day, week, month, year, all

        var id: String { rawValue }

        var label: String {
            switch self {
            case .day: return String(localized: "日")
            case .week: return String(localized: "週")
            case .month: return String(localized: "月")
            case .year: return String(localized: "年")
            case .all: return String(localized: "全て")
            }
        }
    }

    @Binding var selection: Period
    var options: [Period] = Period.allCases

    var body: some View {
        Picker("期間", selection: $selection) {
            ForEach(options) { period in
                Text(period.label).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview("Light") {
    StatefulPreviewWrapper(PeriodSegment.Period.week) { binding in
        PeriodSegment(selection: binding)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OikomiColor.appBackground)
    }
}

#Preview("Dark") {
    StatefulPreviewWrapper(PeriodSegment.Period.week) { binding in
        PeriodSegment(selection: binding)
            .padding()
            .background(OikomiColor.appBackground)
            .preferredColorScheme(.dark)
    }
}

// 簡易プレビュー用 Binding ホルダ。
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: initial)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
