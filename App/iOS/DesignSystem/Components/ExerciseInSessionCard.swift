import OikomiKit
import SwiftUI

/// 進行中セッション内の 1 種目をひとつのカードにまとめる。
///
/// ヘッダ: 種目名 + completed/total chip。
/// 中身: セット行 (InlineSetRow) の縦並び。
/// フッタ: 「+ セット追加」ボタン（クロージャ）。読み取り専用モードでは非表示。
struct ExerciseInSessionCard: View {

    let exercise: Exercise
    let sets: [SetRecord]
    var readOnly: Bool = false
    var onToggleSet: (SetRecord) -> Void = { _ in }
    var onAddSet: () -> Void = {}
    var onDeleteSet: (SetRecord) -> Void = { _ in }
    /// セット行の値部分タップで呼ばれる。編集シート起動用。readOnly 時は無視。
    var onEditSet: (SetRecord) -> Void = { _ in }
    /// ヘッダのメニューから「種目を削除」がタップされたとき呼ばれる。readOnly 時はメニューごと非表示。
    var onDeleteExercise: () -> Void = {}
    /// PR 更新の可能性がある種目に対する推奨ワーキング重量(kg)。非 nil のとき「重さを更新」ボタンを出す。
    var weightUpdateSuggestionKg: Double? = nil
    /// 「重さを更新」ボタンの重量表示に使う単位。
    var weightUnit: WeightUnit = .kg
    /// なぜ更新を勧めるのか（上昇トレンド・PR 更新の可能性など）をボタン下に表示する根拠文。
    var weightUpdateReason: String? = nil
    /// 「重さを更新」ボタンがタップされたとき呼ばれる。未完了セットの重量を推奨値へ更新する。
    var onUpdateWeight: () -> Void = {}

    private var completedCount: Int { sets.count(where: \.isCompleted) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.top, OikomiSpacing.l)
                .padding(.bottom, OikomiSpacing.s)

            Divider()
                .padding(.horizontal, OikomiSpacing.l)

            VStack(spacing: 0) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                    InlineSetRow(
                        set: set,
                        indexInGroup: index + 1,
                        onToggleComplete: readOnly ? nil : { onToggleSet(set) }
                    )
                    .padding(.horizontal, OikomiSpacing.l)
                    .contentShape(Rectangle())
                    .contextMenu {
                        if !readOnly {
                            // 編集を上、削除を下に。色は全体の brandPrimary(オレンジ) tint を継承するため、
                            // 編集はアイコン=オレンジ・文字=黒(primary)。削除は role の赤文字に加え
                            // .tint(.red) でアイコンも赤に揃える。
                            Button {
                                onEditSet(set)
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                onDeleteSet(set)
                            } label: {
                                Label("セットを削除", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                    if index < sets.count - 1 {
                        Divider().padding(.leading, 2 * OikomiSpacing.l)
                    }
                }
            }

            if !readOnly {
                Divider()
                    .padding(.horizontal, OikomiSpacing.l)
                Button(action: onAddSet) {
                    HStack(spacing: OikomiSpacing.xs) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(OikomiColor.brandPrimary)
                        Text("セットを追加")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, OikomiSpacing.l)
                    .padding(.vertical, OikomiSpacing.m)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if let suggestionKg = weightUpdateSuggestionKg {
                    Divider()
                        .padding(.horizontal, OikomiSpacing.l)
                    Button(action: onUpdateWeight) {
                        HStack(alignment: .top, spacing: OikomiSpacing.xs) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(OikomiColor.brandPrimary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(
                                    String(
                                        localized:
                                            "重さを更新 → \(WeightFormatter.string(kilograms: suggestionKg, in: weightUnit))"
                                    )
                                )
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                if let weightUpdateReason {
                                    Text(weightUpdateReason)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, OikomiSpacing.l)
                        .padding(.vertical, OikomiSpacing.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .center, spacing: OikomiSpacing.s) {
            Text(exercise.localizedName)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: OikomiSpacing.s)
            completionChip
            if !readOnly {
                menuButton
            }
        }
    }

    /// 種目への操作（現状は削除のみ）をまとめた「…」メニュー。
    /// 以前は長押しの contextMenu だったが、発見しづらいため明示ボタン化した。
    @ViewBuilder
    private var menuButton: some View {
        Menu {
            Button(role: .destructive) {
                onDeleteExercise()
            } label: {
                Label("種目を削除", systemImage: "trash")
            }
            .tint(.red)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.headline)
                .foregroundStyle(.secondary)
                .contentShape(Circle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var completionChip: some View {
        let totalCount = sets.count
        let allDone = completedCount >= totalCount && totalCount > 0
        HStack(spacing: 4) {
            if allDone {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
            }
            Text("\(completedCount) / \(totalCount)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .lineLimit(1)
        }
        .fixedSize()  // HStack 全体を内容に合わせた本来の幅で固定 (二桁・三桁でも縦に折れない)
        .foregroundStyle(allDone ? Color.green : .secondary)
        .padding(.horizontal, OikomiSpacing.s)
        .padding(.vertical, 4)
        .background((allDone ? Color.green : Color.secondary).opacity(0.14), in: Capsule())
    }
}
