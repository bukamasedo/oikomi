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
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return true }
        return term.localizedStandardContains(needle)
            || (alias?.localizedStandardContains(needle) ?? false)
            || description.localizedStandardContains(needle)
            || (note?.localizedStandardContains(needle) ?? false)
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
        title: String(localized: "トレーニング基礎"),
        footer: String(localized: "Oikomi の「記録」「ホーム」「履歴」画面はすべてこの語彙で構成されています。"),
        entries: [
            GlossaryEntry(
                term: String(localized: "セット"),
                alias: String(localized: "Set"),
                systemImage: "rectangle.stack.fill",
                tint: OikomiColor.brandPrimary,
                description: String(localized: "連続して行う一連のレップのまとまり。例: ベンチプレス 80kg × 8 レップ を 1 セットとして記録します。")
            ),
            GlossaryEntry(
                term: String(localized: "レップ"),
                alias: String(localized: "Rep / Repetition"),
                systemImage: "repeat",
                tint: OikomiColor.brandSecondary,
                description: String(localized: "1 回の挙上動作のこと。8 レップとは同じ重量で 8 回連続して挙げ切ったことを意味します。")
            ),
            GlossaryEntry(
                term: String(localized: "重量"),
                alias: String(localized: "Weight (kg)"),
                systemImage: "scalemass",
                tint: OikomiColor.statBlue,
                description: String(localized: "1 セットで扱う負荷。バーベル種目ではシャフトと付属プレートを合算した総重量を入力します。")
            ),
            GlossaryEntry(
                term: String(localized: "ワーキングセット"),
                alias: String(localized: "Working Set"),
                systemImage: "flame.fill",
                tint: OikomiColor.statOrange,
                description: String(localized: "ウォームアップを除いた本番セット。週次ボリュームや MEV / MAV の集計対象になります。")
            ),
            GlossaryEntry(
                term: String(localized: "ウォームアップ"),
                alias: String(localized: "Warm-up"),
                systemImage: "thermometer.sun.fill",
                tint: OikomiColor.statYellow,
                description: String(
                    localized: "本番セットの前段で関節・神経系を準備する軽いセット。記録時に「ウォームアップ」フラグを立てると、ボリューム集計と PR 判定から除外されます。")
            ),
            GlossaryEntry(
                term: String(localized: "インターバル"),
                alias: String(localized: "Rest Interval"),
                systemImage: "timer",
                tint: OikomiColor.statIndigo,
                description: String(
                    localized: "セット間の休息時間。種目ごとの推奨秒数 (例: スクワット 180 秒、二頭筋カール 60 秒) があらかじめ設定されており、レストタイマーが自動起動します。")
            ),
            GlossaryEntry(
                term: String(localized: "種目"),
                alias: String(localized: "Exercise"),
                systemImage: "dumbbell.fill",
                tint: OikomiColor.brandPrimary,
                description: String(
                    localized: "個別の運動 (ベンチプレス、スクワット 等)。Oikomi にはバーベル・ダンベル・マシン・自重などを含む約 100 種を初期搭載しています。")
            ),
            GlossaryEntry(
                term: String(localized: "カスタム種目"),
                alias: String(localized: "Custom Exercise"),
                systemImage: "square.and.pencil",
                tint: OikomiColor.statPurple,
                description: String(localized: "ユーザーが自作した種目。Free プランは 5 件まで、Pro プランは無制限に作成できます。")
            ),
            GlossaryEntry(
                term: String(localized: "ルーティン"),
                alias: String(localized: "Routine"),
                systemImage: "list.bullet.rectangle.portrait",
                tint: OikomiColor.brandSecondary,
                description: String(
                    localized: "「胸+三頭筋」「PPL: Push 日」など、複数種目をまとめたテンプレート。ホームから 1 タップで開始でき、種目順や前回重量がプリフィルされます。"),
                note: String(localized: "Free プランは 3 件まで、Pro プランは無制限。")
            ),
            GlossaryEntry(
                term: String(localized: "セッション"),
                alias: String(localized: "Workout Session"),
                systemImage: "figure.strengthtraining.traditional",
                tint: OikomiColor.statRed,
                description: String(
                    localized: "1 回のトレーニング全体を表す単位。開始時刻・終了時刻・含まれる全セットを保持し、終了時に HealthKit へ HKWorkout として書き込まれます。")
            ),
        ]
    )

    // MARK: コーチング・分析

    fileprivate static let analytics = GlossarySection(
        title: String(localized: "コーチング・分析"),
        footer: String(localized: "「分析」タブと AI コーチングカードで使われる指標です。コーチング判定はオンデバイスで計算され、外部に送信されません。"),
        entries: [
            GlossaryEntry(
                term: String(localized: "1RM"),
                alias: String(localized: "One Repetition Maximum"),
                systemImage: "star.circle.fill",
                tint: OikomiColor.proAccent,
                description: String(localized: "「1 回だけ挙げ切れる最大重量」のこと。直接測定は怪我のリスクが高いため、Oikomi は実際のセットから推定 1RM を計算します。")
            ),
            GlossaryEntry(
                term: String(localized: "推定 1RM"),
                alias: String(localized: "Estimated 1RM"),
                systemImage: "function",
                tint: OikomiColor.brandPrimary,
                description: String(localized: "実セットの重量とレップ数から計算式で予測した 1RM。種目ごとに最大値が PR として保存され、強度設定や PR 予測の基準になります。")
            ),
            GlossaryEntry(
                term: String(localized: "Epley 式"),
                systemImage: "x.squareroot",
                tint: OikomiColor.statBlue,
                description: String(localized: "1〜10 レップ程度の中レップで精度が高い 1RM 推定式。業界で広く使われる標準式です。"),
                formula: String(localized: "1RM = weight × (1 + reps / 30)")
            ),
            GlossaryEntry(
                term: String(localized: "Brzycki 式"),
                systemImage: "x.squareroot",
                tint: OikomiColor.statIndigo,
                description: String(localized: "低〜中レップで Epley と並んで使われる 1RM 推定式。10 レップを超えると精度が下がります。"),
                formula: String(localized: "1RM = weight × 36 / (37 - reps)")
            ),
            GlossaryEntry(
                term: String(localized: "相対強度"),
                alias: String(localized: "%1RM"),
                systemImage: "percent",
                tint: OikomiColor.statOrange,
                description: String(
                    localized: "扱っている重量が推定 1RM の何 % にあたるかを示す値。筋力 ≥ 85%、筋肥大 65–85%、筋持久 < 65% がおおまかな目安です。"),
                formula: String(localized: "%1RM = weight / estimated1RM × 100")
            ),
            GlossaryEntry(
                term: String(localized: "PR"),
                alias: String(localized: "Personal Record (自己ベスト)"),
                systemImage: "trophy.fill",
                tint: OikomiColor.proAccent,
                description: String(localized: "種目ごとの自己ベスト記録。重量 × レップと、その時点の推定 1RM が保存されます。「分析」タブの自己ベスト一覧で確認できます。")
            ),
            GlossaryEntry(
                term: String(localized: "ボリューム"),
                alias: String(localized: "Volume"),
                systemImage: "chart.bar.fill",
                tint: OikomiColor.brandPrimary,
                description: String(localized: "トレーニング総量を示す指標で、Oikomi では 重量 × レップ の合算で算出します。週次・部位別に集計し、過不足の判断材料にします。"),
                formula: String(localized: "volume = Σ(weight × reps)")
            ),
            GlossaryEntry(
                term: String(localized: "週次総ボリューム"),
                alias: String(localized: "Weekly Volume"),
                systemImage: "calendar",
                tint: OikomiColor.statBlue,
                description: String(localized: "直近 8 週ぶんの週合計ボリュームを棒グラフで表示。長期トレンドの確認とディロード判定の入力になります。")
            ),
            GlossaryEntry(
                term: String(localized: "部位別セット数"),
                alias: String(localized: "Sets per Muscle / week"),
                systemImage: "rectangle.split.3x1.fill",
                tint: OikomiColor.statPurple,
                description: String(localized: "主働筋ごとの週次ワーキングセット数。1 セットが複数の主働筋を持つ場合はそれぞれにフルカウントで加算されます。")
            ),
            GlossaryEntry(
                term: String(localized: "MEV"),
                alias: String(localized: "Minimum Effective Volume"),
                systemImage: "arrow.down.to.line",
                tint: OikomiColor.statGreen,
                description: String(localized: "「最低限有効ボリューム」。これを下回ると筋量維持が難しくなる目安の週セット数で、部位別に設定されています。"),
                note: String(localized: "Schoenfeld らの 2017 メタアナリシスを下敷きにした中央値ベースの初期値。個人差は大きく、v1.1 以降でユーザーカスタマイズを予定。")
            ),
            GlossaryEntry(
                term: String(localized: "MAV"),
                alias: String(localized: "Maximum Adaptive Volume"),
                systemImage: "arrow.up.to.line",
                tint: OikomiColor.statRed,
                description: String(localized: "「最大適応ボリューム」。これを超えると回復が追いつかず適応がむしろ減ってしまう目安の上限値です。")
            ),
            GlossaryEntry(
                term: String(localized: "ディロード"),
                alias: String(localized: "Deload"),
                systemImage: "leaf.fill",
                tint: OikomiColor.statGreen,
                description: String(
                    localized: "1 週間ほど強度を 80% 程度に意図的に落とす計画的な回復期間。連続トレーニング日数の長期化、または週ボリュームの急増を検知した時にコーチングカードで提案します。"),
                note: String(localized: "Free 機能。連続トレ日数・週ボリューム比に加え、HRV 低下検知（翌朝通知）でも強度緩和を提案します。")
            ),
            GlossaryEntry(
                term: String(localized: "ボリューム警告"),
                alias: String(localized: "Volume Alert"),
                systemImage: "exclamationmark.triangle.fill",
                tint: OikomiColor.statOrange,
                description: String(localized: "先週比でボリュームが大幅に変動した時の注意喚起。+50% 超で「過負荷の可能性」、−50% 未満で「不足」を通知します。")
            ),
            GlossaryEntry(
                term: String(localized: "PR 予測"),
                alias: String(localized: "PR Prediction"),
                systemImage: "chart.line.uptrend.xyaxis",
                tint: OikomiColor.proAccent,
                description: String(localized: "直近セッションの最高 1RM が現 PR の 95% 以上に達した時、次回更新の可能性と狙うべき重量を提示します。")
            ),
        ]
    )

    // MARK: コンディション

    fileprivate static let condition = GlossarySection(
        title: String(localized: "コンディション (HealthKit)"),
        footer: String(
            localized: "HealthKit 読み取りと今日のコンディション表示は Free です（長期トレンドの分析は Pro）。Oikomi はオンデバイスで参照し、外部送信は行いません。"),
        entries: [
            GlossaryEntry(
                term: String(localized: "HRV"),
                alias: String(localized: "Heart Rate Variability (心拍変動)"),
                systemImage: "waveform.path.ecg",
                tint: OikomiColor.statPink,
                description: String(localized: "心拍の拍動間隔のばらつき。副交感神経の活性度合いを反映し、自分の平常値より低下していると疲労蓄積のサインとされます。"),
                note: String(localized: "単位: ミリ秒 (ms)。Apple Watch では夜間の SDNN として測定されます。")
            ),
            GlossaryEntry(
                term: String(localized: "安静時心拍数"),
                alias: String(localized: "Resting Heart Rate / RHR"),
                systemImage: "heart.fill",
                tint: OikomiColor.statRed,
                description: String(localized: "起床直後など安静時の心拍数。トレーニング適応で長期的に漸減することが多く、急上昇は体調不良やオーバートレーニングの目安になります。"),
                note: String(localized: "単位: bpm (拍/分)。")
            ),
            GlossaryEntry(
                term: String(localized: "睡眠時間"),
                alias: String(localized: "Sleep Hours"),
                systemImage: "moon.zzz.fill",
                tint: OikomiColor.statIndigo,
                description: String(localized: "前夜の総睡眠時間。筋トレからの回復・タンパク合成・神経系リフレッシュに直結する最大の入力です。")
            ),
            GlossaryEntry(
                term: String(localized: "体組成"),
                alias: String(localized: "Body Composition"),
                systemImage: "figure",
                tint: OikomiColor.statBlue,
                description: String(localized: "体重・体脂肪率・除脂肪体重 (LBM) などの総称。「分析 → ボディ」で長期推移を確認できます。"),
                note: String(localized: "除脂肪体重 = 体重 × (1 − 体脂肪率)。筋量変化の近似指標として使えます。")
            ),
        ]
    )

    // MARK: 部位

    fileprivate static let body = GlossarySection(
        title: String(localized: "部位"),
        footer: String(localized: "1 種目に主働筋を 1 つ以上設定し、ボリューム集計時にはそれぞれフルカウントで加算します。"),
        entries: [
            GlossaryEntry(
                term: String(localized: "胸"),
                alias: String(localized: "Chest"),
                systemImage: "figure.arms.open",
                tint: OikomiColor.statRed,
                description: String(localized: "大胸筋。ベンチプレス・ダンベルフライ・腕立て伏せなどが代表的種目です。")
            ),
            GlossaryEntry(
                term: String(localized: "背中"),
                alias: String(localized: "Back"),
                systemImage: "figure.walk",
                tint: OikomiColor.statBlue,
                description: String(localized: "広背筋・僧帽筋中下部・脊柱起立筋を含む広い領域。デッドリフト・懸垂・ロウ系が中心です。")
            ),
            GlossaryEntry(
                term: String(localized: "肩"),
                alias: String(localized: "Shoulders"),
                systemImage: "figure.cooldown",
                tint: OikomiColor.statYellow,
                description: String(localized: "三角筋 (前部・中部・後部)。ショルダープレス・サイドレイズなどで個別に刺激します。")
            ),
            GlossaryEntry(
                term: String(localized: "上腕二頭筋"),
                alias: String(localized: "Biceps"),
                systemImage: "figure.boxing",
                tint: OikomiColor.statOrange,
                description: String(localized: "腕の前面、肘屈曲の主働筋。バーベル/ダンベルカール、ハンマーカールなど。")
            ),
            GlossaryEntry(
                term: String(localized: "上腕三頭筋"),
                alias: String(localized: "Triceps"),
                systemImage: "figure.boxing",
                tint: OikomiColor.statOrange,
                description: String(localized: "腕の後面、肘伸展の主働筋。トライセプスエクステンション、ディップス、ナローベンチプレスなど。")
            ),
            GlossaryEntry(
                term: String(localized: "前腕"),
                alias: String(localized: "Forearms"),
                systemImage: "hand.raised.fill",
                tint: OikomiColor.statOrange,
                description: String(localized: "握力と手首屈伸を司る筋群。リストカール・ファーマーズキャリーで補強します。")
            ),
            GlossaryEntry(
                term: String(localized: "腹"),
                alias: String(localized: "Abs"),
                systemImage: "figure.core.training",
                tint: OikomiColor.statGreen,
                description: String(localized: "腹直筋。クランチ・レッグレイズ・プランクなどの体幹種目で刺激します。")
            ),
            GlossaryEntry(
                term: String(localized: "腹斜筋"),
                alias: String(localized: "Obliques"),
                systemImage: "figure.core.training",
                tint: OikomiColor.statGreen,
                description: String(localized: "体側を覆う回旋・側屈の主働筋。サイドベンド、ロシアンツイストなど。")
            ),
            GlossaryEntry(
                term: String(localized: "大腿四頭筋"),
                alias: String(localized: "Quads"),
                systemImage: "figure.strengthtraining.functional",
                tint: OikomiColor.statPurple,
                description: String(localized: "太もも前面。スクワット・レッグプレス・レッグエクステンションが代表種目です。")
            ),
            GlossaryEntry(
                term: String(localized: "ハムストリング"),
                alias: String(localized: "Hamstrings"),
                systemImage: "figure.strengthtraining.functional",
                tint: OikomiColor.statPurple,
                description: String(localized: "太もも後面。ルーマニアンデッドリフト・レッグカール・グッドモーニングなど。")
            ),
            GlossaryEntry(
                term: String(localized: "臀部"),
                alias: String(localized: "Glutes"),
                systemImage: "figure.strengthtraining.functional",
                tint: OikomiColor.statPink,
                description: String(localized: "大殿筋・中殿筋。ヒップスラスト・ブルガリアンスクワット・スモウデッドリフトなど。")
            ),
            GlossaryEntry(
                term: String(localized: "ふくらはぎ"),
                alias: String(localized: "Calves"),
                systemImage: "figure.run",
                tint: OikomiColor.statIndigo,
                description: String(localized: "下腿三頭筋 (腓腹筋・ヒラメ筋)。スタンディング/シーテッドカーフレイズで刺激します。")
            ),
            GlossaryEntry(
                term: String(localized: "全身"),
                alias: String(localized: "Full Body"),
                systemImage: "figure",
                tint: OikomiColor.brandPrimary,
                description: String(localized: "クリーン、スナッチ、バーピーなど複数部位を横断的に動員する種目。部位別集計の対象外として扱います。")
            ),
        ]
    )

    // MARK: プラットフォーム / Pro

    fileprivate static let platform = GlossarySection(
        title: String(localized: "プラットフォーム・Pro"),
        footer: String(localized: "Pro プランの詳細は「設定 → Pro にアップグレード」から確認できます。"),
        entries: [
            GlossaryEntry(
                term: String(localized: "Oikomi Pro"),
                systemImage: "star.fill",
                tint: OikomiColor.proAccent,
                description:
                    String(
                        localized:
                            "月額 ¥780 / 年額 ¥4,500 のサブスクリプション。高度な AI コーチング（PR 予測・ボリューム警告）・コンディションの長期トレンド・iCloud 同期・無制限ルーティン/カスタム種目・CSV エクスポートが解放されます。HRV 連動ディロード推奨と HealthKit 読み取りは Free です。"
                    ),
                note: String(localized: "初回 14 日間は無料トライアル。App Store の購入履歴から自動更新を停止できます。")
            ),
            GlossaryEntry(
                term: String(localized: "Live Activity"),
                alias: String(localized: "Dynamic Island"),
                systemImage: "rectangle.dashed",
                tint: OikomiColor.brandPrimary,
                description: String(
                    localized: "iOS のロック画面とアイランドにワークアウト進行状況 (経過時間・現在の種目・次インターバル) を常時表示する機能。Free / Pro 共通。")
            ),
            GlossaryEntry(
                term: String(localized: "iCloud 同期"),
                alias: String(localized: "CloudKit"),
                systemImage: "icloud.fill",
                tint: OikomiColor.statBlue,
                description:
                    String(
                        localized:
                            "iPhone・Apple Watch・iPad・Mac 間で記録を自動同期。データは Apple の iCloud プライベートデータベースに格納され、Oikomi 開発者からも参照できません。"
                    ),
                note: String(localized: "Pro 限定。設定変更後はアプリの再起動が必要です。")
            ),
            GlossaryEntry(
                term: String(localized: "HealthKit"),
                systemImage: "heart.text.square.fill",
                tint: OikomiColor.statRed,
                description:
                    String(
                        localized:
                            "Apple のヘルスケアフレームワーク。Oikomi はワークアウト完了時に HKWorkout を書き込み (Free)、HRV / 安静時心拍 / 睡眠 / 体組成を読み取り (Free) します（長期トレンドの可視化は Pro）。"
                    )
            ),
            GlossaryEntry(
                term: String(localized: "Workout Buddy"),
                alias: String(localized: "Apple Watch ワークアウトアプリ連携"),
                systemImage: "applewatch",
                tint: OikomiColor.statGreen,
                description:
                    String(
                        localized:
                            "Apple Watch 標準ワークアウトと同じセッション (HKWorkoutSession) を共有します。Oikomi で記録を開始すると、Buddy 側にも自動でワークアウト中表示が出ます。"
                    )
            ),
            GlossaryEntry(
                term: String(localized: "App Intents"),
                alias: String(localized: "Siri ショートカット"),
                systemImage: "mic.fill",
                tint: OikomiColor.statPurple,
                description: String(localized: "「Hey Siri、ベンチプレスを記録」のように音声・ショートカット・スマートスタックから入力できる仕組みです。")
            ),
            GlossaryEntry(
                term: String(localized: "Free プラン"),
                systemImage: "person.fill",
                tint: OikomiColor.textSecondary,
                description: String(
                    localized: "無料プラン。基本記録・履歴無制限・Watch スタンドアロン記録・HealthKit 書き込みが利用可能。ルーティン 3 件 / カスタム種目 5 件まで。")
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
