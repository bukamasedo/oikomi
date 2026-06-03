import SwiftUI

/// 年・月を 2 つのホイールで選ばせる共通シート。
/// 履歴カレンダーの月ラベルタップから提示し、任意の過去月へ素早く移動するために使う。
///
/// Date 非依存に保つため Int の Binding のみを受け取る（年範囲は呼び出し側が算出して渡す）。
/// 未来月のキャップは呼び出し側の責務（確定値を月初へ丸めてからクランプする）。
struct MonthYearPickerSheet: View {

    @Binding var year: Int
    @Binding var month: Int  // 1...12
    let yearRange: ClosedRange<Int>
    /// 「今月へ」で現在年月へ戻すためのコールバック。
    var onJumpToCurrentMonth: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: OikomiSpacing.l) {
                HStack(spacing: 0) {
                    Picker("年", selection: $year) {
                        ForEach(Array(yearRange), id: \.self) { y in
                            Text("\(String(y))年").tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    Picker("月", selection: $month) {
                        ForEach(1...12, id: \.self) { m in
                            Text("\(m)月").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.top, OikomiSpacing.s)
            .background(OikomiColor.appBackground)
            .navigationTitle("年月を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("今月へ") {
                        onJumpToCurrentMonth()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("Light") {
    StatefulPreviewWrapper(2026) { yearBinding in
        StatefulPreviewWrapper(6) { monthBinding in
            Color.clear.sheet(isPresented: .constant(true)) {
                MonthYearPickerSheet(
                    year: yearBinding,
                    month: monthBinding,
                    yearRange: 2023...2026,
                    onJumpToCurrentMonth: {}
                )
                .presentationDetents([.height(320)])
            }
        }
    }
}
