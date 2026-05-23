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

    private var completedCount: Int { sets.filter(\.isCompleted).count }

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
                        onToggleComplete: readOnly ? nil : { onToggleSet(set) },
                        onEditTap: readOnly ? nil : { onEditSet(set) }
                    )
                    .padding(.horizontal, OikomiSpacing.l)
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing) {
                        if !readOnly {
                            Button(role: .destructive) {
                                onDeleteSet(set)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
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
            }
        }
        .background(
            OikomiColor.cardBackground, in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous))
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .center, spacing: OikomiSpacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if exercise.defaultRestSeconds > 0 {
                    Text("レスト \(exercise.defaultRestSeconds) 秒")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: OikomiSpacing.s)
            completionChip
        }
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
