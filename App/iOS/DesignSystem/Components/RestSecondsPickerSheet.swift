import SwiftUI

/// レスト秒数を 15 秒刻みのホイール Picker で選択させる共通シート。
///
/// 3 箇所で再利用される:
/// - ExerciseDetailView: 種目マスターの defaultRestSeconds 編集（allowsDefault=false）
/// - CustomExerciseFormSheet: 新規カスタム種目作成時の初期値（allowsDefault=false）
/// - RoutineEditorView: ルーティン内の個別種目上書き（allowsDefault=true、nil 許容）
struct RestSecondsPickerSheet: View {

    /// 表示中の選択値。nil は「種目デフォルトを使う」状態（allowsDefault が true のときだけ意味を持つ）。
    @Binding var seconds: Int?
    /// 「デフォルト」エントリを Picker に含めるか。
    let allowsDefault: Bool
    /// allowsDefault=true のとき、デフォルトエントリのラベルに表示する種目側の秒数。
    let defaultValueForDisplay: Int
    let title: String

    @Environment(\.dismiss) private var dismiss

    /// 0, 15, 30, ..., 600（41 段階）。15 秒刻みで体感操作に十分。
    static let candidateSeconds: [Int] = stride(from: 0, through: 600, by: 15).map { $0 }

    init(
        seconds: Binding<Int?>,
        allowsDefault: Bool,
        defaultValueForDisplay: Int = 90,
        title: String = String(localized: "レスト時間")
    ) {
        self._seconds = seconds
        self.allowsDefault = allowsDefault
        self.defaultValueForDisplay = defaultValueForDisplay
        self.title = title
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: OikomiSpacing.l) {
                Picker(title, selection: $seconds) {
                    if allowsDefault {
                        Text("デフォルト (\(Self.formatLabel(defaultValueForDisplay)))")
                            .tag(Int?.none)
                    }
                    ForEach(Self.candidateSeconds, id: \.self) { sec in
                        Text(Self.formatLabel(sec))
                            .tag(Optional(sec))
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()

                Spacer(minLength: 0)
            }
            .padding(.horizontal, OikomiSpacing.l)
            .padding(.top, OikomiSpacing.s)
            .background(OikomiColor.appBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
                if allowsDefault {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("戻す") {
                            seconds = nil
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    static func formatLabel(_ s: Int) -> String {
        if s == 0 { return String(localized: "なし") }
        return String(localized: "\(s) 秒")
    }
}
