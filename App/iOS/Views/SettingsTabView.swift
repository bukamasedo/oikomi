import OikomiKit
import StoreKit
import SwiftData
import SwiftUI

/// アプリ設定タブ。
///
/// 仕様書§7.1: HealthKit / 通知 / 課金 / ジム自宅モード切替 / アカウント
/// v0.1 では HealthKit 状態 / 場所モード / オンボーディング再表示 / データリセット / Pro 導線 を提供。
struct SettingsTabView: View {

    @Environment(\.modelContext) private var modelContext

    @AppStorage("OikomiPreferredLocation") private var preferredLocationRaw: String = Location.gym.rawValue
    @AppStorage(WeeklyTrainingTarget.storageKey) private var weeklyTargetDays: Int =
        WeeklyTrainingTarget.defaultDays
    @AppStorage(SharedModelContainer.cloudKitEnabledKey) private var cloudKitEnabled: Bool = true
    @State private var showResetConfirm = false
    @State private var showProSheet = false
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
            List {
                Section { proHeroRow }
                    .listRowInsets(
                        EdgeInsets(
                            top: OikomiSpacing.s, leading: OikomiSpacing.l, bottom: OikomiSpacing.s,
                            trailing: OikomiSpacing.l)
                    )
                    .listRowBackground(Color.clear)
                preferenceSection
                iCloudSection
                healthKitSection
                dataSection
                #if DEBUG
                    developerSection
                #endif
                aboutSection
            }
            .navigationTitle("設定")
            .alert("エラー", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("全データを削除しますか？", isPresented: $showResetConfirm) {
                Button("全て削除", role: .destructive) { resetAllData() }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("セッション・PR・ルーティン・カスタム種目をすべて削除します。シード種目は再投入されます。Apple Watch のローカルデータも削除されます。")
            }
            .sheet(isPresented: $showProSheet) {
                ProUpgradeSheet()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            #if DEBUG
                .alert("テストデータを削除しますか？", isPresented: $showMockClearConfirm) {
                    Button("削除", role: .destructive) {
                        Task { await clearMockData() }
                    }
                    Button("キャンセル", role: .cancel) {}
                } message: {
                    Text("MockDataGenerator が生成したセッション・ルーティン・HealthKit データを削除します。実データは保持されます。")
                }
            #endif
        }
    }

    // MARK: - Sections

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
                    Text(isPro ? "Oikomi Pro" : "Pro にアップグレード")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(isPro ? "全機能を利用できます" : "HRV 連動コーチング / iCloud 同期 / 無制限ルーティン")
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
    private var preferenceSection: some View {
        Section {
            Picker(selection: $preferredLocationRaw) {
                Text("ジム").tag(Location.gym.rawValue)
                Text("自宅").tag(Location.home.rawValue)
            } label: {
                Label("トレーニング場所", systemImage: "location")
            }

            Picker(selection: $weeklyTargetDays) {
                ForEach(WeeklyTrainingTarget.allowedRange, id: \.self) { days in
                    Text("週 \(days) 日").tag(days)
                }
            } label: {
                Label("週次トレーニング目標", systemImage: "calendar.badge.checkmark")
            }

            NavigationLink {
                AppIconPickerView()
            } label: {
                Label("アプリアイコン", systemImage: "app.badge")
            }
        } header: {
            Text("環境")
        } footer: {
            Text("ホーム画面とウィジェットの達成リングがこの目標日数を基準に表示されます。筋トレは休養日込みのサイクルが前提なので、無理のない頻度を選んでください。")
        }
    }

    @ViewBuilder
    private var healthKitSection: some View {
        Section("ヘルスケア") {
            NavigationLink {
                HealthKitDetailView()
            } label: {
                Label("HealthKit 連携", systemImage: "heart.text.square")
            }
        }
    }

    @ViewBuilder
    private var iCloudSection: some View {
        Section {
            Toggle(isOn: $cloudKitEnabled) {
                HStack {
                    Label("iCloud 同期", systemImage: "icloud")
                    if !ProGate.canUseICloudSync {
                        Spacer()
                        Text("Pro")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.3))
                            )
                    }
                }
            }
            .disabled(!ProGate.canUseICloudSync)
            .onChange(of: cloudKitEnabled) { _, _ in
                showCloudKitChangeAlert = true
            }

            HStack {
                Text("現在の状態")
                Spacer()
                statusBadge
            }

            if !ProGate.canUseICloudSync {
                Button {
                    showProSheet = true
                } label: {
                    Label("Pro にアップグレード", systemImage: "star.fill")
                        .foregroundStyle(.tint)
                }
            }
        } header: {
            Text("マルチデバイス同期")
        } footer: {
            Text(
                "iPhone・Apple Watch・iPad・Mac 間で記録を自動同期します。すべての計算はオンデバイス、データは Apple の iCloud（ユーザーのプライベートデータベース）に保存されます。設定変更後はアプリの再起動が必要です。Pro 限定機能です。"
            )
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
        Section("データ") {
            Button {
                showOnboarding = true
            } label: {
                Label("オンボーディングを再表示", systemImage: "play.circle")
            }
            exportButton
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("すべてのデータを削除", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var exportButton: some View {
        if ProGate.canExportData {
            Button {
                exportData()
            } label: {
                HStack {
                    Label("CSV としてエクスポート", systemImage: "square.and.arrow.up")
                    if let url = exportedURL {
                        Spacer()
                        ShareLink(item: url) {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        } else {
            Button {
                showProSheet = true
            } label: {
                HStack {
                    Label("CSV としてエクスポート", systemImage: "square.and.arrow.up")
                    Spacer()
                    Text("Pro")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.3))
                        )
                }
            }
        }
    }

    private func exportData() {
        do {
            let url = try DataExporter.writeCSVToTemp(context: modelContext)
            exportedURL = url
        } catch {
            errorMessage = "エクスポートに失敗: \(error.localizedDescription)"
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section("情報") {
            NavigationLink {
                GlossaryView()
            } label: {
                Label("用語解説", systemImage: "book.closed")
            }
            LabeledContent("バージョン") {
                Text("0.1.0")
                    .foregroundStyle(.secondary)
            }
            LabeledContent("OikomiKit") {
                Text(OikomiKit.version)
                    .foregroundStyle(.secondary)
                    .font(.callout.monospaced())
            }
        }
    }

    #if DEBUG
        @ViewBuilder
        private var developerSection: some View {
            Section {
                Button {
                    Task { await generateMockData() }
                } label: {
                    HStack {
                        Label("テストデータ (6週間) を生成", systemImage: "wand.and.stars")
                        Spacer()
                        if mockIsRunning {
                            ProgressView()
                        }
                    }
                }
                .disabled(mockIsRunning)

                if let summary = mockSummary {
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
                    .padding(.vertical, 2)
                }

                Button(role: .destructive) {
                    showMockClearConfirm = true
                } label: {
                    Label("テストデータを削除", systemImage: "trash.slash")
                        .foregroundStyle(.red)
                }
                .disabled(mockIsRunning)
            } header: {
                Text("開発者ツール")
            } footer: {
                Text(
                    "DEBUG ビルド限定。月・水・金 を Push / Pull / Legs にローテーションした 6 週間分のリアルな履歴を生成し、HealthKit にも HRV / 安静時心拍数 / 睡眠 / 体重 / HKWorkout を書き込みます（権限ダイアログが出ます）。"
                )
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
                errorMessage = "テストデータ生成失敗: \(error.localizedDescription)"
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
                errorMessage = "テストデータ削除失敗: \(error.localizedDescription)"
            }
        }
    #endif

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
            errorMessage = "リセット失敗: \(error.localizedDescription)"
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
                Text("HealthKit のデータ読み取りは Pro 機能で、HRV や睡眠スコアからトレーニング負荷を最適化します。書き込みは Free でも有効です。")
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

    private var monthlyProduct: Product? {
        subscriptionManager.products.first(where: { $0.id == ProductIDs.proMonthly })
    }
    private var yearlyProduct: Product? {
        subscriptionManager.products.first(where: { $0.id == ProductIDs.proYearly })
    }
    private var selectedProduct: Product? {
        subscriptionManager.products.first(where: { $0.id == selectedProductID })
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
                        ? "Pro が有効になりました。"
                        : "復元可能な購入が見つかりませんでした。")
            }
            .alert(
                "エラー",
                isPresented: Binding(
                    get: { subscriptionManager.lastError != nil },
                    set: { _ in subscriptionManager.clearLastError() }
                )
            ) {
                Button("OK") {}
            } message: {
                Text(subscriptionManager.lastError ?? "")
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
            ProBullet(title: "HRV 連動 AI コーチング", detail: "HRV 低下を検知して自動ディロード推奨")
            ProBullet(title: "線形回帰 PR 予測", detail: "直近セッションのトレンドから次回 PR を予測")
            ProBullet(title: "HealthKit 詳細読み取り", detail: "HRV・睡眠・安静時心拍数で負荷を自動調整")
            ProBullet(title: "iCloud 同期", detail: "iPhone・Watch・Mac でデータ共有")
            ProBullet(title: "Family Sharing", detail: "最大 6 名で利用可能")
            ProBullet(title: "ルーティン・カスタム種目 無制限", detail: "Free は 5 / 5 まで")
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var pricingSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.products.isEmpty {
                ProgressView()
                    .padding(.vertical, 24)
            } else {
                if let yearly = yearlyProduct {
                    priceRow(
                        product: yearly,
                        label: "年額プラン",
                        note: "実質 ¥483/月（月額比 38% オフ）"
                    )
                }
                if let monthly = monthlyProduct {
                    priceRow(
                        product: monthly,
                        label: "月額プラン",
                        note: nil
                    )
                }
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var ctaSection: some View {
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
        .padding(.horizontal, 24)
        .disabled(subscriptionManager.purchaseInProgress || selectedProduct == nil)
    }

    private var ctaLabel: String {
        if subscriptionManager.isEligibleForIntroOffer {
            return "14日間無料で始める"
        }
        return "購入する"
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

            HStack(spacing: 16) {
                Link("利用規約", destination: URL(string: "https://example.com/terms")!)
                Link("プライバシーポリシー", destination: URL(string: "https://example.com/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
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
