import OikomiKit
import SwiftUI

/// 用語解説ビュー。設定 → 情報 → 用語解説 から開く。
///
/// Apple ヘルスケアの「項目について」と同じ温度感で、アプリ内に出てくる
/// トレーニング・分析・コンディション・課金まわりの用語をカテゴリ別にまとめる。
/// `.searchable` で横断検索できる。
struct GlossaryView: View {

    @State private var searchText = ""

    private var sections: [GlossarySection] { GlossarySection.all }

    private var visibleSections: [GlossarySection] {
        sections.compactMap { section in
            let filtered = section.filtered(by: searchText)
            return filtered.isEmpty ? nil : section.with(entries: filtered)
        }
    }

    var body: some View {
        List {
            if visibleSections.isEmpty {
                Section {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                ForEach(visibleSections) { section in
                    Section {
                        ForEach(section.entries) { entry in
                            GlossaryRow(entry: entry)
                        }
                    } header: {
                        Text(section.title)
                    } footer: {
                        if let footer = section.footer {
                            Text(footer)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("用語解説")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "用語・読みで検索"
        )
    }
}

// MARK: - Row

private struct GlossaryRow: View {

    let entry: GlossaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: OikomiSpacing.s) {
                Image(systemName: entry.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(entry.tint)
                    .frame(width: 22, alignment: .center)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.term)
                        .font(.headline)
                    if let alias = entry.alias {
                        Text(alias)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(entry.description)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let formula = entry.formula {
                Text(formula)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.primary)
                    .padding(OikomiSpacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: OikomiRadius.tile, style: .continuous)
                            .fill(OikomiColor.elevatedBackground)
                    )
            }

            if let note = entry.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, OikomiSpacing.xs)
    }
}

// MARK: - Models

private struct GlossaryEntry: Identifiable, Hashable {
    let id = UUID()
    let term: String
    let alias: String?
    let systemImage: String
    let tint: Color
    let description: String
    let formula: String?
    let note: String?

    init(
        term: String,
        alias: String? = nil,
        systemImage: String,
        tint: Color,
        description: String,
        formula: String? = nil,
        note: String? = nil
    ) {
        self.term = term
        self.alias = alias
        self.systemImage = systemImage
        self.tint = tint
        self.description = description
        self.formula = formula
        self.note = note
    }

    func matches(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        let needle = trimmed.lowercased()
        return term.lowercased().contains(needle)
            || (alias?.lowercased().contains(needle) ?? false)
            || description.lowercased().contains(needle)
            || (note?.lowercased().contains(needle) ?? false)
    }
}

private struct GlossarySection: Identifiable {
    let id = UUID()
    let title: String
    let footer: String?
    let entries: [GlossaryEntry]

    func filtered(by query: String) -> [GlossaryEntry] {
        entries.filter { $0.matches(query) }
    }

    func with(entries: [GlossaryEntry]) -> GlossarySection {
        GlossarySection(title: title, footer: footer, entries: entries)
    }
}

// MARK: - Content

extension GlossarySection {

    static var all: [GlossarySection] {
        [trainingBasics, analytics, condition, body, platform]
    }

    // MARK: トレーニング基礎

    fileprivate static let trainingBasics = GlossarySection(
        title: "トレーニング基礎",
        footer: "Oikomi の「記録」「ホーム」「履歴」画面はすべてこの語彙で構成されています。",
        entries: [
            GlossaryEntry(
                term: "セット",
                alias: "Set",
                systemImage: "rectangle.stack.fill",
                tint: OikomiColor.brandPrimary,
                description: "連続して行う一連のレップのまとまり。例: ベンチプレス 80kg × 8 レップ を 1 セットとして記録します。"
            ),
            GlossaryEntry(
                term: "レップ",
                alias: "Rep / Repetition",
                systemImage: "repeat",
                tint: OikomiColor.brandSecondary,
                description: "1 回の挙上動作のこと。8 レップとは同じ重量で 8 回連続して挙げ切ったことを意味します。"
            ),
            GlossaryEntry(
                term: "重量",
                alias: "Weight (kg)",
                systemImage: "scalemass",
                tint: OikomiColor.statBlue,
                description: "1 セットで扱う負荷。バーベル種目ではシャフトと付属プレートを合算した総重量を入力します。"
            ),
            GlossaryEntry(
                term: "ワーキングセット",
                alias: "Working Set",
                systemImage: "flame.fill",
                tint: OikomiColor.statOrange,
                description: "ウォームアップを除いた本番セット。週次ボリュームや MEV / MAV の集計対象になります。"
            ),
            GlossaryEntry(
                term: "ウォームアップ",
                alias: "Warm-up",
                systemImage: "thermometer.sun.fill",
                tint: OikomiColor.statYellow,
                description: "本番セットの前段で関節・神経系を準備する軽いセット。記録時に「ウォームアップ」フラグを立てると、ボリューム集計と PR 判定から除外されます。"
            ),
            GlossaryEntry(
                term: "インターバル",
                alias: "Rest Interval",
                systemImage: "timer",
                tint: OikomiColor.statIndigo,
                description: "セット間の休息時間。種目ごとの推奨秒数 (例: スクワット 180 秒、二頭筋カール 60 秒) があらかじめ設定されており、レストタイマーが自動起動します。"
            ),
            GlossaryEntry(
                term: "種目",
                alias: "Exercise",
                systemImage: "dumbbell.fill",
                tint: OikomiColor.brandPrimary,
                description: "個別の運動 (ベンチプレス、スクワット 等)。Oikomi にはバーベル・ダンベル・マシン・自重などを含む約 100 種を初期搭載しています。"
            ),
            GlossaryEntry(
                term: "カスタム種目",
                alias: "Custom Exercise",
                systemImage: "square.and.pencil",
                tint: OikomiColor.statPurple,
                description: "ユーザーが自作した種目。Free プランは 5 件まで、Pro プランは無制限に作成できます。"
            ),
            GlossaryEntry(
                term: "ルーティン",
                alias: "Routine",
                systemImage: "list.bullet.rectangle.portrait",
                tint: OikomiColor.brandSecondary,
                description: "「胸+三頭筋」「PPL: Push 日」など、複数種目をまとめたテンプレート。ホームから 1 タップで開始でき、種目順や前回重量がプリフィルされます。",
                note: "Free プランは 3 件まで、Pro プランは無制限。"
            ),
            GlossaryEntry(
                term: "セッション",
                alias: "Workout Session",
                systemImage: "figure.strengthtraining.traditional",
                tint: OikomiColor.statRed,
                description: "1 回のトレーニング全体を表す単位。開始時刻・終了時刻・含まれる全セットを保持し、終了時に HealthKit へ HKWorkout として書き込まれます。"
            ),
        ]
    )

    // MARK: コーチング・分析

    fileprivate static let analytics = GlossarySection(
        title: "コーチング・分析",
        footer: "「分析」タブと AI コーチングカードで使われる指標です。コーチング判定はオンデバイスで計算され、外部に送信されません。",
        entries: [
            GlossaryEntry(
                term: "1RM",
                alias: "One Repetition Maximum",
                systemImage: "star.circle.fill",
                tint: OikomiColor.proAccent,
                description: "「1 回だけ挙げ切れる最大重量」のこと。直接測定は怪我のリスクが高いため、Oikomi は実際のセットから推定 1RM を計算します。"
            ),
            GlossaryEntry(
                term: "推定 1RM",
                alias: "Estimated 1RM",
                systemImage: "function",
                tint: OikomiColor.brandPrimary,
                description: "実セットの重量とレップ数から計算式で予測した 1RM。種目ごとに最大値が PR として保存され、強度設定や PR 予測の基準になります。"
            ),
            GlossaryEntry(
                term: "Epley 式",
                systemImage: "x.squareroot",
                tint: OikomiColor.statBlue,
                description: "1〜10 レップ程度の中レップで精度が高い 1RM 推定式。業界で広く使われる標準式です。",
                formula: "1RM = weight × (1 + reps / 30)"
            ),
            GlossaryEntry(
                term: "Brzycki 式",
                systemImage: "x.squareroot",
                tint: OikomiColor.statIndigo,
                description: "低〜中レップで Epley と並んで使われる 1RM 推定式。10 レップを超えると精度が下がります。",
                formula: "1RM = weight × 36 / (37 - reps)"
            ),
            GlossaryEntry(
                term: "相対強度",
                alias: "%1RM",
                systemImage: "percent",
                tint: OikomiColor.statOrange,
                description: "扱っている重量が推定 1RM の何 % にあたるかを示す値。筋力 ≥ 85%、筋肥大 65–85%、筋持久 < 65% がおおまかな目安です。",
                formula: "%1RM = weight / estimated1RM × 100"
            ),
            GlossaryEntry(
                term: "PR",
                alias: "Personal Record (自己ベスト)",
                systemImage: "trophy.fill",
                tint: OikomiColor.proAccent,
                description: "種目ごとの自己ベスト記録。重量 × レップと、その時点の推定 1RM が保存されます。「分析」タブの自己ベスト一覧で確認できます。"
            ),
            GlossaryEntry(
                term: "ボリューム",
                alias: "Volume",
                systemImage: "chart.bar.fill",
                tint: OikomiColor.brandPrimary,
                description: "トレーニング総量を示す指標で、Oikomi では 重量 × レップ の合算で算出します。週次・部位別に集計し、過不足の判断材料にします。",
                formula: "volume = Σ(weight × reps)"
            ),
            GlossaryEntry(
                term: "週次総ボリューム",
                alias: "Weekly Volume",
                systemImage: "calendar",
                tint: OikomiColor.statBlue,
                description: "直近 8 週ぶんの週合計ボリュームを棒グラフで表示。長期トレンドの確認とディロード判定の入力になります。"
            ),
            GlossaryEntry(
                term: "部位別セット数",
                alias: "Sets per Muscle / week",
                systemImage: "rectangle.split.3x1.fill",
                tint: OikomiColor.statPurple,
                description: "主働筋ごとの週次ワーキングセット数。1 セットが複数の主働筋を持つ場合はそれぞれにフルカウントで加算されます。"
            ),
            GlossaryEntry(
                term: "MEV",
                alias: "Minimum Effective Volume",
                systemImage: "arrow.down.to.line",
                tint: OikomiColor.statGreen,
                description: "「最低限有効ボリューム」。これを下回ると筋量維持が難しくなる目安の週セット数で、部位別に設定されています。",
                note: "Schoenfeld らの 2017 メタアナリシスを下敷きにした中央値ベースの初期値。個人差は大きく、v1.1 以降でユーザーカスタマイズを予定。"
            ),
            GlossaryEntry(
                term: "MAV",
                alias: "Maximum Adaptive Volume",
                systemImage: "arrow.up.to.line",
                tint: OikomiColor.statRed,
                description: "「最大適応ボリューム」。これを超えると回復が追いつかず適応がむしろ減ってしまう目安の上限値です。"
            ),
            GlossaryEntry(
                term: "ディロード",
                alias: "Deload",
                systemImage: "leaf.fill",
                tint: OikomiColor.statGreen,
                description: "1 週間ほど強度を 80% 程度に意図的に落とす計画的な回復期間。連続トレーニング日数の長期化、または週ボリュームの急増を検知した時にコーチングカードで提案します。",
                note: "Pro 機能。v0.1 は連続日数 + ボリューム比の簡易判定。v1.1 で HRV ベースの判定を追加予定です。"
            ),
            GlossaryEntry(
                term: "ボリューム警告",
                alias: "Volume Alert",
                systemImage: "exclamationmark.triangle.fill",
                tint: OikomiColor.statOrange,
                description: "先週比でボリュームが大幅に変動した時の注意喚起。+50% 超で「過負荷の可能性」、−50% 未満で「不足」を通知します。"
            ),
            GlossaryEntry(
                term: "PR 予測",
                alias: "PR Prediction",
                systemImage: "chart.line.uptrend.xyaxis",
                tint: OikomiColor.proAccent,
                description: "直近セッションの最高 1RM が現 PR の 95% 以上に達した時、次回更新の可能性と狙うべき重量を提示します。"
            ),
        ]
    )

    // MARK: コンディション

    fileprivate static let condition = GlossarySection(
        title: "コンディション (HealthKit)",
        footer: "HealthKit 読み取りは Pro 機能です。Oikomi はオンデバイスで参照し、外部送信は行いません。",
        entries: [
            GlossaryEntry(
                term: "HRV",
                alias: "Heart Rate Variability (心拍変動)",
                systemImage: "waveform.path.ecg",
                tint: OikomiColor.statPink,
                description: "心拍の拍動間隔のばらつき。副交感神経の活性度合いを反映し、自分の平常値より低下していると疲労蓄積のサインとされます。",
                note: "単位: ミリ秒 (ms)。Apple Watch では夜間の SDNN として測定されます。"
            ),
            GlossaryEntry(
                term: "安静時心拍数",
                alias: "Resting Heart Rate / RHR",
                systemImage: "heart.fill",
                tint: OikomiColor.statRed,
                description: "起床直後など安静時の心拍数。トレーニング適応で長期的に漸減することが多く、急上昇は体調不良やオーバートレーニングの目安になります。",
                note: "単位: bpm (拍/分)。"
            ),
            GlossaryEntry(
                term: "睡眠時間",
                alias: "Sleep Hours",
                systemImage: "moon.zzz.fill",
                tint: OikomiColor.statIndigo,
                description: "前夜の総睡眠時間。筋トレからの回復・タンパク合成・神経系リフレッシュに直結する最大の入力です。"
            ),
            GlossaryEntry(
                term: "体組成",
                alias: "Body Composition",
                systemImage: "figure",
                tint: OikomiColor.statBlue,
                description: "体重・体脂肪率・除脂肪体重 (LBM) などの総称。「分析 → ボディ」で長期推移を確認できます。",
                note: "除脂肪体重 = 体重 × (1 − 体脂肪率)。筋量変化の近似指標として使えます。"
            ),
        ]
    )

    // MARK: 部位

    fileprivate static let body = GlossarySection(
        title: "部位",
        footer: "1 種目に主働筋を 1 つ以上設定し、ボリューム集計時にはそれぞれフルカウントで加算します。",
        entries: [
            GlossaryEntry(
                term: "胸",
                alias: "Chest",
                systemImage: "figure.arms.open",
                tint: OikomiColor.statRed,
                description: "大胸筋。ベンチプレス・ダンベルフライ・腕立て伏せなどが代表的種目です。"
            ),
            GlossaryEntry(
                term: "背中",
                alias: "Back",
                systemImage: "figure.walk",
                tint: OikomiColor.statBlue,
                description: "広背筋・僧帽筋中下部・脊柱起立筋を含む広い領域。デッドリフト・懸垂・ロウ系が中心です。"
            ),
            GlossaryEntry(
                term: "肩",
                alias: "Shoulders",
                systemImage: "figure.cooldown",
                tint: OikomiColor.statYellow,
                description: "三角筋 (前部・中部・後部)。ショルダープレス・サイドレイズなどで個別に刺激します。"
            ),
            GlossaryEntry(
                term: "上腕二頭筋",
                alias: "Biceps",
                systemImage: "figure.boxing",
                tint: OikomiColor.statOrange,
                description: "腕の前面、肘屈曲の主働筋。バーベル/ダンベルカール、ハンマーカールなど。"
            ),
            GlossaryEntry(
                term: "上腕三頭筋",
                alias: "Triceps",
                systemImage: "figure.boxing",
                tint: OikomiColor.statOrange,
                description: "腕の後面、肘伸展の主働筋。トライセプスエクステンション、ディップス、ナローベンチプレスなど。"
            ),
            GlossaryEntry(
                term: "前腕",
                alias: "Forearms",
                systemImage: "hand.raised.fill",
                tint: OikomiColor.statOrange,
                description: "握力と手首屈伸を司る筋群。リストカール・ファーマーズキャリーで補強します。"
            ),
            GlossaryEntry(
                term: "腹",
                alias: "Abs",
                systemImage: "figure.core.training",
                tint: OikomiColor.statGreen,
                description: "腹直筋。クランチ・レッグレイズ・プランクなどの体幹種目で刺激します。"
            ),
            GlossaryEntry(
                term: "腹斜筋",
                alias: "Obliques",
                systemImage: "figure.core.training",
                tint: OikomiColor.statGreen,
                description: "体側を覆う回旋・側屈の主働筋。サイドベンド、ロシアンツイストなど。"
            ),
            GlossaryEntry(
                term: "大腿四頭筋",
                alias: "Quads",
                systemImage: "figure.strengthtraining.functional",
                tint: OikomiColor.statPurple,
                description: "太もも前面。スクワット・レッグプレス・レッグエクステンションが代表種目です。"
            ),
            GlossaryEntry(
                term: "ハムストリング",
                alias: "Hamstrings",
                systemImage: "figure.strengthtraining.functional",
                tint: OikomiColor.statPurple,
                description: "太もも後面。ルーマニアンデッドリフト・レッグカール・グッドモーニングなど。"
            ),
            GlossaryEntry(
                term: "臀部",
                alias: "Glutes",
                systemImage: "figure.strengthtraining.functional",
                tint: OikomiColor.statPink,
                description: "大殿筋・中殿筋。ヒップスラスト・ブルガリアンスクワット・スモウデッドリフトなど。"
            ),
            GlossaryEntry(
                term: "ふくらはぎ",
                alias: "Calves",
                systemImage: "figure.run",
                tint: OikomiColor.statIndigo,
                description: "下腿三頭筋 (腓腹筋・ヒラメ筋)。スタンディング/シーテッドカーフレイズで刺激します。"
            ),
            GlossaryEntry(
                term: "全身",
                alias: "Full Body",
                systemImage: "figure",
                tint: OikomiColor.brandPrimary,
                description: "クリーン、スナッチ、バーピーなど複数部位を横断的に動員する種目。部位別集計の対象外として扱います。"
            ),
        ]
    )

    // MARK: プラットフォーム / Pro

    fileprivate static let platform = GlossarySection(
        title: "プラットフォーム・Pro",
        footer: "Pro プランの詳細は「設定 → Pro にアップグレード」から確認できます。",
        entries: [
            GlossaryEntry(
                term: "Oikomi Pro",
                systemImage: "star.fill",
                tint: OikomiColor.proAccent,
                description:
                    "月額 ¥780 / 年額 ¥5,800 のサブスクリプション。HRV 連動 AI コーチング・HealthKit 読み取り・iCloud 同期・無制限ルーティン/カスタム種目・CSV エクスポートが解放されます。",
                note: "初回 14 日間は無料トライアル。App Store の購入履歴から自動更新を停止できます。"
            ),
            GlossaryEntry(
                term: "Live Activity",
                alias: "Dynamic Island",
                systemImage: "rectangle.dashed",
                tint: OikomiColor.brandPrimary,
                description: "iOS のロック画面とアイランドにワークアウト進行状況 (経過時間・現在の種目・次インターバル) を常時表示する機能。Free / Pro 共通。"
            ),
            GlossaryEntry(
                term: "iCloud 同期",
                alias: "CloudKit",
                systemImage: "icloud.fill",
                tint: OikomiColor.statBlue,
                description:
                    "iPhone・Apple Watch・iPad・Mac 間で記録を自動同期。データは Apple の iCloud プライベートデータベースに格納され、Oikomi 開発者からも参照できません。",
                note: "Pro 限定。設定変更後はアプリの再起動が必要です。"
            ),
            GlossaryEntry(
                term: "HealthKit",
                systemImage: "heart.text.square.fill",
                tint: OikomiColor.statRed,
                description:
                    "Apple のヘルスケアフレームワーク。Oikomi はワークアウト完了時に HKWorkout を書き込み (Free)、HRV / 安静時心拍 / 睡眠 / 体組成を読み取り (Pro) します。"
            ),
            GlossaryEntry(
                term: "Workout Buddy",
                alias: "Apple Watch ワークアウトアプリ連携",
                systemImage: "applewatch",
                tint: OikomiColor.statGreen,
                description:
                    "Apple Watch 標準ワークアウトと同じセッション (HKWorkoutSession) を共有します。Oikomi で記録を開始すると、Buddy 側にも自動でワークアウト中表示が出ます。"
            ),
            GlossaryEntry(
                term: "App Intents",
                alias: "Siri ショートカット",
                systemImage: "mic.fill",
                tint: OikomiColor.statPurple,
                description: "「Hey Siri、ベンチプレスを記録」のように音声・ショートカット・スマートスタックから入力できる仕組みです。"
            ),
            GlossaryEntry(
                term: "Free プラン",
                systemImage: "person.fill",
                tint: OikomiColor.textSecondary,
                description: "無料プラン。基本記録・履歴無制限・Watch スタンドアロン記録・HealthKit 書き込みが利用可能。ルーティン 3 件 / カスタム種目 5 件まで。"
            ),
        ]
    )
}

// MARK: - Preview

#Preview("Light") {
    NavigationStack {
        GlossaryView()
    }
}

#Preview("Dark") {
    NavigationStack {
        GlossaryView()
    }
    .preferredColorScheme(.dark)
}
