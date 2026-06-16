import OikomiKit
import StoreKit
import SwiftData
import SwiftUI

/// アプリ設定タブ。
///
/// 仕様書§7.1: HealthKit / 通知 / 課金 / ジム自宅モード切替
/// v0.1 では HealthKit 状態 / 場所モード / オンボーディング再表示 / データリセット / Pro 導線 を提供。
struct SettingsTabView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @AppStorage("OikomiPreferredLocation") private var preferredLocationRaw: String = Location.gym.rawValue
    @AppStorage(WeeklyTrainingTarget.storageKey) private var weeklyTargetDays: Int =
        WeeklyTrainingTarget.defaultDays
    @AppStorage(SharedModelContainer.cloudKitEnabledKey) private var cloudKitEnabled: Bool = true
    @AppStorage(UnitPreference.storageKey, store: .sharedAppGroup)
    private var weightUnitRaw: String = UnitPreference.defaultUnit.rawValue
    @AppStorage(TrainingProfilePreference.experienceKey) private var experienceLevelRaw: String =
        TrainingProfile.default.experience.rawValue
    @AppStorage(TrainingProfilePreference.goalKey) private var trainingGoalRaw: String =
        TrainingProfile.default.goal.rawValue

    // 通知トグル群（デフォルト全 ON / 朝 7:00）
    @AppStorage("OikomiNotif_Rest") private var notifRestEnabled: Bool = true
    @AppStorage("OikomiNotif_Weekly") private var notifWeeklyEnabled: Bool = true
    @AppStorage("OikomiNotif_PRPrediction") private var notifPRPredictionEnabled: Bool = true
    @AppStorage("OikomiNotif_HRVDeload") private var notifHRVDeloadEnabled: Bool = true
    @AppStorage("OikomiNotif_ForgottenSession") private var notifForgottenEnabled: Bool = true
    @AppStorage("OikomiNotif_Trial") private var notifTrialEnabled: Bool = true
    @AppStorage("OikomiNotif_TimePreset") private var notifTimePresetRaw: Int =
        NotificationTimePreset.morning.rawValue
    @State private var showResetConfirm = false
    @State private var showProSheet = false
    @State private var showTipSheet = false
    @State private var showOnboarding = false
    @State private var errorMessage: String?
    @State private var showCloudKitChangeAlert = false
    @State private var exportedURL: URL?

    #if DEBUG
        @State private var mockIsRunning = false
        @State private var mockSummary: MockDataGenerator.Summary?
        @State private var showMockClearConfirm = false
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: OikomiSpacing.l) {
                    proHeroRow
                    tipJarRow
                    preferenceSection
                    notificationsSection
                    integrationsSection
                    dataSection
                    #if DEBUG
                        developerSection
                    #endif
                    aboutSection
                }
                .padding(.horizontal, OikomiSpacing.l)
                .padding(.bottom, OikomiSpacing.xxl)
            }
            .scrollContentBackground(.hidden)
            .background(OikomiColor.appBackground)
            .navigationTitle("設定")
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            // ブランド tint(オレンジ)がキャンセルボタンに流れ込むのを避けるため、
            // アラートだけ neutral tint の不可視ホストに載せる(destructive は赤のまま)。
            .background {
                Color.clear
                    .tint(.primary)
                    .alert("全データを削除しますか？", isPresented: $showResetConfirm) {
                        Button("全て削除", role: .destructive) { resetAllData() }
                        Button("キャンセル", role: .cancel) {}
                    } message: {
                        Text("セッション・PR・ルーティン・カスタム種目をすべて削除します。シード種目は再投入されます。Apple Watch のローカルデータも削除されます。")
                    }
            }
            .sheet(isPresented: $showProSheet) {
                ProUpgradeSheet()
            }
            .sheet(isPresented: $showTipSheet) {
                TipJarSheet()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            #if DEBUG
                .background {
                    Color.clear
                    .tint(.primary)
                    .alert("テストデータを削除しますか？", isPresented: $showMockClearConfirm) {
                        Button("削除", role: .destructive) {
                            Task { await clearMockData() }
                        }
                        Button("キャンセル", role: .cancel) {}
                    } message: {
                        Text("MockDataGenerator が生成したセッション・ルーティン・HealthKit データを削除します。実データは保持されます。")
                    }
                }
            #endif
        }
    }

    // MARK: - Sections

    /// ホーム画面と同一のカード見た目（角丸 16・cardBackground・内側 16pt padding）の汎用コンテナ。
    /// 純正 List の insetGrouped ではなく `HomeView` の自作カードに合わせる。
    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: OikomiSpacing.s) {
            content()
        }
        // 行ごとにアイコン幅が違ってもテキスト開始位置を揃えるため、
        // カード内の Label はアイコン列を固定幅にする。
        .labelStyle(SettingsRowLabelStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(OikomiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                .fill(OikomiColor.cardBackground)
        )
    }

    /// カード内の先頭に置く見出し行。アイコンの大きさ・色はホーム / 分析画面の見出しと統一し、
    /// 本文と同サイズ・`.primary` のモノクロにする。下に約 16pt の余白を取る。
    @ViewBuilder
    private func cardHeader(_ title: LocalizedStringKey, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.bottom, OikomiSpacing.s)
    }

    /// カード内の 1 行（左ラベル + 右トレーリング）。最低タップ高を確保する。
    @ViewBuilder
    private func settingsRow<L: View, T: View>(
        @ViewBuilder label: () -> L,
        @ViewBuilder trailing: () -> T = { EmptyView() }
    ) -> some View {
        HStack(spacing: OikomiSpacing.m) {
            label()
            Spacer(minLength: OikomiSpacing.s)
            trailing()
        }
        .frame(minHeight: 30)
    }

    /// 画面遷移行（右端に chevron）。NavigationLink の青 tint を避けて primary に統一。
    @ViewBuilder
    private func navRow<Destination: View>(
        _ title: LocalizedStringKey, systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            settingsRow {
                Label(title, systemImage: systemImage)
            } trailing: {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    /// メニュー Picker 行（左ラベル + 右に選択値）。List 行と同様の見た目にする。
    @ViewBuilder
    private func pickerRow<SelectionValue: Hashable, Options: View>(
        _ title: LocalizedStringKey, systemImage: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder options: () -> Options
    ) -> some View {
        settingsRow {
            Label(title, systemImage: systemImage)
        } trailing: {
            Picker("", selection: selection) {
                options()
            }
            .labelsHidden()
            .tint(.secondary)
            // メニュー Picker の選択値（例:「キログラム (kg)」）が幅不足で改行するのを防ぐ。
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    @ViewBuilder
    private var proHeroRow: some View {
        let isPro = ProGate.isProActive
        Button {
            showProSheet = true
        } label: {
            HStack(spacing: OikomiSpacing.m) {
                ZStack {
                    Circle().fill(.white.opacity(0.22))
                    Image(systemName: isPro ? "star.fill" : "star.circle.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isPro ? "Oikomi Pro" : String(localized: "Pro にアップグレード"))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(isPro ? String(localized: "全機能を利用できます") : ProFeatureCatalog.heroSummary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(OikomiSpacing.l)
            .background(
                LinearGradient(
                    colors: isPro
                        ? [OikomiColor.proAccent, OikomiColor.brandSecondary]
                        : [OikomiColor.brandPrimary, OikomiColor.brandSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tipJarRow: some View {
        Button {
            showTipSheet = true
        } label: {
            HStack(spacing: OikomiSpacing.m) {
                ZStack {
                    Circle().fill(OikomiColor.brandPrimary.opacity(0.18))
                    Image(systemName: "heart.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(OikomiColor.brandPrimary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("開発者を支援")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(tipJarSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(OikomiSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: OikomiRadius.card, style: .continuous)
                    .fill(OikomiColor.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private var tipJarSubtitle: String {
        String(localized: "気が向いたらお気持ちで応援を")
    }

    @ViewBuilder
    private var preferenceSection: some View {
        settingsCard {
            cardHeader("環境", systemImage: "slider.horizontal.3")

            pickerRow("トレーニング場所", systemImage: "location", selection: $preferredLocationRaw) {
                Text("ジム").tag(Location.gym.rawValue)
                Text("自宅").tag(Location.home.rawValue)
            }
            Divider()
            pickerRow("重量単位", systemImage: "scalemass", selection: $weightUnitRaw) {
                ForEach(WeightUnit.allCases, id: \.rawValue) { unit in
                    Text("\(unit.localizedName) (\(unit.symbol))").tag(unit.rawValue)
                }
            }
            .onChange(of: weightUnitRaw) { _, newValue in
                // App Group UserDefaults は iPhone↔Watch 間では共有されないため、
                // 設定変更を WC 経由で Watch に明示同期する。
                guard let unit = WeightUnit(rawValue: newValue) else { return }
                WCSyncBridge.shared.sendUnitPreferenceUpdate(unit)
            }
            Divider()
            pickerRow(
                "週次トレーニング目標", systemImage: "calendar.badge.checkmark",
                selection: $weeklyTargetDays
            ) {
                ForEach(WeeklyTrainingTarget.allowedRange, id: \.self) { days in
                    Text("週 \(days) 日").tag(days)
                }
            }
            Divider()
            pickerRow(
                "経験レベル", systemImage: "figure.strengthtraining.traditional",
                selection: $experienceLevelRaw
            ) {
                ForEach(ExperienceLevel.allCases, id: \.rawValue) { level in
                    Text(level.displayName).tag(level.rawValue)
                }
            }
            Divider()
            pickerRow("トレーニング目標", systemImage: "target", selection: $trainingGoalRaw) {
                ForEach(TrainingGoal.allCases, id: \.rawValue) { goal in
                    Text(goal.displayName).tag(goal.rawValue)
                }
            }
            Divider()
            navRow("アプリアイコン", systemImage: "app.badge") {
                AppIconPickerView()
            }
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        settingsCard {
            cardHeader("通知", systemImage: "bell.badge")

            Toggle(isOn: $notifRestEnabled) {
                notificationRow(kind: .rest)
            }
            Divider()
            Toggle(isOn: $notifWeeklyEnabled) {
                notificationRow(kind: .weekly)
            }
            Divider()
            Toggle(isOn: $notifPRPredictionEnabled) {
                notificationRow(kind: .prPrediction, proGated: !ProGate.canUseAdvancedCoaching)
            }
            .disabled(!ProGate.canUseAdvancedCoaching)
            Divider()
            Toggle(isOn: $notifHRVDeloadEnabled) {
                notificationRow(kind: .hrvDeload)
            }
            Divider()
            Toggle(isOn: $notifForgottenEnabled) {
                notificationRow(kind: .forgottenSession)
            }
            Divider()
            Toggle(isOn: $notifTrialEnabled) {
                notificationRow(kind: .trial)
            }
            Divider()
            pickerRow("通知時刻", systemImage: "clock", selection: $notifTimePresetRaw) {
                ForEach(NotificationTimePreset.allCases, id: \.rawValue) { preset in
                    Text(preset.displayName).tag(preset.rawValue)
                }
            }

            if !ProGate.canUseAdvancedCoaching {
                Divider()
                Text("PR 予測通知は Pro 限定です。HRV 連動ディロード推奨は Free で使えます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onChange(of: notifRestEnabled) { _, _ in rescheduleNotifications() }
        .onChange(of: notifWeeklyEnabled) { _, _ in rescheduleNotifications() }
        .onChange(of: notifPRPredictionEnabled) { _, _ in rescheduleNotifications() }
        .onChange(of: notifHRVDeloadEnabled) { _, _ in rescheduleNotifications() }
        .onChange(of: notifForgottenEnabled) { _, _ in rescheduleNotifications() }
        .onChange(of: notifTrialEnabled) { _, _ in rescheduleNotifications() }
        .onChange(of: notifTimePresetRaw) { _, _ in rescheduleNotifications() }
    }

    @ViewBuilder
    private func notificationRow(kind: NotificationKind, proGated: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(kind.displayName)
                if proGated {
                    Text("Pro")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(OikomiColor.proAccent.opacity(0.18), in: Capsule())
                        .foregroundStyle(OikomiColor.proAccent)
                }
            }
            Text(kind.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func rescheduleNotifications() {
        Task { @MainActor in
            await NotificationCoordinator.rescheduleAll()
        }
    }

    /// HealthKit と iCloud という外部データ連携をひとまとめにしたカード。
    /// 単独項目（旧「ヘルスケア」）が浮かないよう、似た性質の設定を 1 グループに集約する。
    @ViewBuilder
    private var integrationsSection: some View {
        settingsCard {
            cardHeader("連携・同期", systemImage: "link")

            navRow("HealthKit 連携", systemImage: "heart.text.square") {
                HealthKitDetailView()
            }
            Divider()
            Toggle(isOn: $cloudKitEnabled) {
                Label("iCloud 同期", systemImage: "icloud")
            }
            .disabled(!ProGate.canUseICloudSync)
            .onChange(of: cloudKitEnabled) { _, _ in
                showCloudKitChangeAlert = true
            }
            Divider()
            settingsRow {
                Text("現在の状態")
            } trailing: {
                statusBadge
            }

            if !ProGate.canUseICloudSync {
                Divider()
                Button {
                    showProSheet = true
                } label: {
                    settingsRow {
                        Label("Pro にアップグレード", systemImage: "star.fill")
                            .foregroundStyle(.tint)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .alert("再起動が必要です", isPresented: $showCloudKitChangeAlert) {
            Button("OK") {}
        } message: {
            Text("iCloud 同期の設定変更を反映するには、アプリを完全に終了して再度開いてください。")
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch SharedModelContainer.activeCloudKitMode {
        case .enabled:
            Label("同期中", systemImage: "checkmark.icloud.fill")
                .foregroundStyle(.green)
                .font(.callout)
        case .fallback:
            Label("失敗・ローカル動作", systemImage: "exclamationmark.icloud")
                .foregroundStyle(.orange)
                .font(.callout)
        case .disabled:
            Label("無効", systemImage: "icloud.slash")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
    }

    @ViewBuilder
    private var dataSection: some View {
        settingsCard {
            cardHeader("データ", systemImage: "tray.full")

            Button {
                showOnboarding = true
            } label: {
                settingsRow {
                    Label {
                        Text("オンボーディングを再表示")
                    } icon: {
                        Image(systemName: "play.circle")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            Divider()
            exportButton
            Divider()
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                settingsRow {
                    Label("すべてのデータを削除", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var exportButton: some View {
        if ProGate.canExportData {
            Button {
                exportData()
            } label: {
                settingsRow {
                    Label {
                        Text("CSV としてエクスポート")
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.accentColor)
                    }
                } trailing: {
                    if let url = exportedURL {
                        ShareLink(item: url) {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        } else {
            Button {
                showProSheet = true
            } label: {
                settingsRow {
                    Label {
                        Text("CSV としてエクスポート")
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.accentColor)
                    }
                } trailing: {
                    Text("Pro")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.3))
                        )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        }
    }

    private func exportData() {
        do {
            let url = try DataExporter.writeCSVToTemp(context: modelContext)
            exportedURL = url
        } catch {
            errorMessage = String(localized: "エクスポートに失敗: \(error.localizedDescription)")
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        settingsCard {
            cardHeader("情報", systemImage: "info.circle")

            // 言語切替は iOS 標準の「設定 App → Oikomi → 言語」に委ねる（HIG 準拠）。
            // ここはその画面への導線。アプリは ja/en の 2 ローカライズを同梱しているため
            // OS が自動で言語ピッカーを提供する。
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                settingsRow {
                    Label("言語", systemImage: "globe")
                } trailing: {
                    Text(verbatim: currentLanguageDisplay)
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.up.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            Divider()
            navRow("用語解説", systemImage: "book.closed") {
                GlossaryView()
            }
            Divider()
            settingsRow {
                Text("バージョン")
            } trailing: {
                Text(appVersionDisplay)
                    .foregroundStyle(.secondary)
            }
            Divider()
            settingsRow {
                Text("OikomiKit")
            } trailing: {
                Text(OikomiKit.version)
                    .foregroundStyle(.secondary)
                    .font(.callout.monospaced())
            }
        }
    }

    #if DEBUG
        @ViewBuilder
        private var developerSection: some View {
            settingsCard {
                cardHeader("開発者ツール", systemImage: "hammer")

                Button {
                    Task { await generateMockData() }
                } label: {
                    settingsRow {
                        Label("テストデータ (6週間) を生成", systemImage: "wand.and.stars")
                    } trailing: {
                        if mockIsRunning {
                            ProgressView()
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .disabled(mockIsRunning)

                if let summary = mockSummary {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("生成完了")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        Text("セッション: \(summary.sessionsCreated) / セット: \(summary.setsCreated)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text("ルーティン: \(summary.routinesCreated) / PR 更新: \(summary.personalRecordsTouched)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(
                            summary.didWriteHealthKit
                                ? "HealthKit サンプル: \(summary.healthSamplesWritten)"
                                : "HealthKit: 権限なし / スキップ"
                        )
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                Button(role: .destructive) {
                    showMockClearConfirm = true
                } label: {
                    settingsRow {
                        Label("テストデータを削除", systemImage: "trash.slash")
                            .foregroundStyle(.red)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(mockIsRunning)

                Divider()
                Text(
                    "DEBUG ビルド限定。月・水・金 を Push / Pull / Legs にローテーションした 6 週間分のリアルな履歴を生成し、HealthKit にも HRV / 安静時心拍数 / 睡眠 / 体重 / HKWorkout を書き込みます（権限ダイアログが出ます）。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        private func generateMockData() async {
            mockIsRunning = true
            mockSummary = nil
            defer { mockIsRunning = false }
            do {
                let summary = try await MockDataGenerator.generateRecentHistory(
                    context: modelContext,
                    weeks: 6,
                    writeToHealthKit: true
                )
                mockSummary = summary
            } catch {
                errorMessage = String(localized: "テストデータ生成失敗: \(error.localizedDescription)")
            }
        }

        private func clearMockData() async {
            mockIsRunning = true
            defer { mockIsRunning = false }
            do {
                try await MockDataGenerator.clearMockData(
                    context: modelContext,
                    removeFromHealthKit: true
                )
                mockSummary = nil
            } catch {
                errorMessage = String(localized: "テストデータ削除失敗: \(error.localizedDescription)")
            }
        }
    #endif

    private var appVersionDisplay: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(short) (\(build))"
    }

    /// 現在アプリが解決している言語を、その言語自身の名前（endonym）で表示する。
    /// `Bundle.main.preferredLocalizations` は端末言語＋アプリ別言語設定を反映した実効値。
    private var currentLanguageDisplay: String {
        let code = Bundle.main.preferredLocalizations.first ?? "ja"
        return code.hasPrefix("en") ? "English" : "日本語"
    }

    // MARK: - Actions

    private func resetAllData() {
        do {
            // SwiftData の Cascade に任せて全消し
            try modelContext.delete(model: WorkoutSession.self)
            try modelContext.delete(model: SetRecord.self)
            try modelContext.delete(model: Routine.self)
            try modelContext.delete(model: RoutineExercise.self)
            try modelContext.delete(model: PersonalRecord.self)
            try modelContext.delete(model: HealthSnapshot.self)
            try modelContext.delete(model: Exercise.self)
            try modelContext.save()
            // シード再投入
            try ExerciseRepository(context: modelContext).seedIfNeeded()
            // Apple Watch のローカルデータも削除する
            WCSyncBridge.shared.sendBulkDelete()
        } catch {
            errorMessage = String(localized: "リセット失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - Row Label Style

/// 設定カードの行ラベル用スタイル。アイコン列を固定幅にすることで、
/// SF Symbol ごとに字幅が違ってもテキストの開始位置（左端）を揃える。
private struct SettingsRowLabelStyle: LabelStyle {
    var iconWidth: CGFloat = 26

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: OikomiSpacing.s) {
            configuration.icon
                .frame(width: iconWidth, alignment: .center)
            configuration.title
        }
    }
}

// MARK: - HealthKit Detail

private struct HealthKitDetailView: View {

    @State private var isAvailable = false
    @State private var didRequest = false

    var body: some View {
        List {
            Section {
                LabeledContent("デバイス対応") {
                    Text(isAvailable ? "利用可能" : "未対応")
                        .foregroundStyle(isAvailable ? .green : .secondary)
                }
            } footer: {
                Text("HealthKit のデータ読み取りは Free で、HRV や睡眠から今日のコンディションとディロード提案を行います。長期トレンドの分析は Pro。書き込みも Free です。")
            }

            Section {
                Button {
                    Task { @MainActor in
                        try? await HealthStore.shared.requestWorkoutWriteAuthorization()
                        didRequest = true
                    }
                } label: {
                    Label("権限を再リクエスト", systemImage: "arrow.clockwise")
                }
            } footer: {
                if didRequest {
                    Text("リクエストを送信しました。詳細はヘルスケアアプリ→プロフィール→Apple Health 接続中のApp→Oikomi で確認できます。")
                }
            }
        }
        .navigationTitle("HealthKit 連携")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isAvailable = await HealthStore.shared.isAvailable
        }
    }
}

// MARK: - Pro Sheet

private struct ProUpgradeSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProductID: String = ProductIDs.proYearly
    @State private var showRestoredAlert = false
    @State private var showError = false

    private var monthlyProduct: Product? {
        subscriptionManager.products.first(where: { $0.id == ProductIDs.proMonthly })
    }
    private var yearlyProduct: Product? {
        subscriptionManager.products.first(where: { $0.id == ProductIDs.proYearly })
    }
    private var selectedProduct: Product? {
        subscriptionManager.products.first(where: { $0.id == selectedProductID })
    }

    /// Guideline 3.1.2: トライアル長と「終了後に課金される金額・期間」を一文で結びつける。
    /// 価格は StoreKit の `displayPrice` から取得し、ストアフロント／通貨に追従させる。
    private var trialTermsText: String? {
        guard subscriptionManager.isEligibleForIntroOffer, let product = selectedProduct else { return nil }
        let unit = product.id == ProductIDs.proYearly ? String(localized: "年") : String(localized: "月")
        return String(localized: "14日間無料、その後 \(product.displayPrice)/\(unit)")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    bulletsSection
                    pricingSection
                    ctaSection
                    secondarySection
                }
                .padding(.bottom, 24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("購入を復元しました", isPresented: $showRestoredAlert) {
                Button("OK") {}
            } message: {
                Text(
                    subscriptionManager.isProActive
                        ? String(localized: "Pro が有効になりました。")
                        : String(localized: "復元可能な購入が見つかりませんでした。"))
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { subscriptionManager.clearLastError() }
            } message: {
                Text(subscriptionManager.lastError ?? "")
            }
            .onChange(of: subscriptionManager.lastError) { _, newValue in
                // 商品ロード失敗時は本体 UI に LoadFailureView が出るのでアラートでは出さない。
                // 購入経路のエラーのみアラートで拾う。
                if case .failed = subscriptionManager.loadState {
                    showError = false
                } else {
                    showError = newValue != nil
                }
            }
            .task {
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
            }
            .onChange(of: subscriptionManager.isProActive) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("Oikomi Pro")
                .font(.largeTitle.weight(.bold))
            if subscriptionManager.isEligibleForIntroOffer {
                Text("14 日間無料でお試し")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 24)
    }

    @ViewBuilder
    private var bulletsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(ProFeatureCatalog.allFeatures) { feature in
                ProBullet(title: feature.title, detail: feature.description)
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var pricingSection: some View {
        VStack(spacing: 12) {
            switch subscriptionManager.loadState {
            case .idle, .loading:
                ProgressView()
                    .padding(.vertical, 24)
            case .failed(let message):
                LoadFailureView(
                    title: String(localized: "価格情報を取得できませんでした"),
                    message: message,
                    onRetry: { Task { await subscriptionManager.loadProducts() } }
                )
                .padding(.vertical, 16)
            case .loaded:
                if let yearly = yearlyProduct {
                    priceRow(
                        product: yearly,
                        label: String(localized: "年額プラン"),
                        note: yearlyNote(yearly: yearly, monthly: monthlyProduct)
                    )
                }
                if let monthly = monthlyProduct {
                    priceRow(
                        product: monthly,
                        label: String(localized: "月額プラン"),
                        note: nil
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var ctaSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await purchaseSelected() }
            } label: {
                HStack {
                    if subscriptionManager.purchaseInProgress {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(ctaLabel)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                subscriptionManager.purchaseInProgress
                    || selectedProduct == nil
                    || subscriptionManager.loadState != .loaded
            )

            if let trialTermsText {
                Text(trialTermsText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
    }

    private var ctaLabel: String {
        if subscriptionManager.isEligibleForIntroOffer {
            return String(localized: "14日間無料で始める")
        }
        return String(localized: "購入する")
    }

    @ViewBuilder
    private var secondarySection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await restorePurchases() }
            } label: {
                Text("購入を復元")
                    .font(.subheadline)
            }
            .disabled(subscriptionManager.purchaseInProgress)

            // Guideline 3.1.2: 自動更新の条件を購入導線と同一画面に明示する。
            Text(Self.autoRenewDisclosure)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Link("利用規約", destination: URL(string: "https://bukamasedo.github.io/oikomi/legal/terms/")!)
                Link("プライバシーポリシー", destination: URL(string: "https://bukamasedo.github.io/oikomi/legal/privacy/")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
    }

    /// 自動更新サブスクリプションの定型開示文。月額/年額のどちらも対象。
    static let autoRenewDisclosure =
        String(localized: "サブスクリプションは期間終了の 24 時間前までに解約しない限り自動更新され、Apple ID に課金されます。")
        + String(localized: "無料トライアル中に解約した場合は課金されません。購入後は App Store の「サブスクリプション」からいつでも管理・解約できます。")

    /// 年額プランの「実質月額」と月額比割引率を StoreKit の価格から算出する。
    /// ハードコードを避け、ストアフロント／通貨に追従させる（表記の正確性）。
    private func yearlyNote(yearly: Product, monthly: Product?) -> String {
        let perMonth = (yearly.price / 12).formatted(yearly.priceFormatStyle)
        guard let monthly, monthly.price > 0 else {
            return String(localized: "実質 \(perMonth)/月")
        }
        let discountPercent = (1 - yearly.price / (monthly.price * 12)) * 100
        let pct = NSDecimalNumber(decimal: discountPercent).intValue
        guard pct > 0 else { return String(localized: "実質 \(perMonth)/月") }
        return String(localized: "実質 \(perMonth)/月（月額比 \(pct)% オフ）")
    }

    @ViewBuilder
    private func priceRow(product: Product, label: String, note: String?) -> some View {
        let isHighlighted = product.id == selectedProductID
        Button {
            selectedProductID = product.id
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: isHighlighted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isHighlighted ? Color.accentColor : .secondary)
                    Text(label)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(product.displayPrice)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHighlighted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isHighlighted ? Color.accentColor : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        do {
            _ = try await subscriptionManager.purchase(product)
        } catch {
            // SubscriptionManager 内部で lastError がセットされない経路もあるためここでも保険
            print("[Oikomi.sub] purchase failed: \(error)")
        }
    }

    private func restorePurchases() async {
        do {
            try await subscriptionManager.restore()
            showRestoredAlert = true
        } catch {
            print("[Oikomi.sub] restore failed: \(error)")
        }
    }
}

private struct ProBullet: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SettingsTabView()
}
