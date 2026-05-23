import OikomiKit
import SwiftUI
import UIKit

struct AppIconOption: Identifiable, Equatable {
    /// nil = 既定アイコン（CFBundlePrimaryIcon）
    let alternateName: String?
    let title: String
    let subtitle: String
    let previewAssetName: String

    var id: String { alternateName ?? "__primary__" }

    static let all: [AppIconOption] = [
        .init(
            alternateName: nil,
            title: "ダンベル",
            subtitle: "デフォルト・万人向け筋トレ",
            previewAssetName: "AppIconPreviewDumbbell"
        ),
        .init(
            alternateName: "AppIconBarbell",
            title: "バーベル",
            subtitle: "本格派・追い込み感",
            previewAssetName: "AppIconPreviewBarbell"
        ),
        .init(
            alternateName: "AppIconProtein",
            title: "プロテイン",
            subtitle: "栄養・回復寄り",
            previewAssetName: "AppIconPreviewProtein"
        ),
    ]
}

struct AppIconPickerView: View {

    @State private var currentAlternateName: String? = UIApplication.shared.alternateIconName
    @State private var isChanging = false
    @State private var errorMessage: String?

    private static let iconBackgroundColor = Color(
        red: 0.90980, green: 0.36471, blue: 0.01569)

    var body: some View {
        List {
            Section {
                ForEach(AppIconOption.all) { option in
                    Button {
                        select(option)
                    } label: {
                        row(for: option)
                    }
                    .buttonStyle(.plain)
                    .disabled(isChanging)
                }
            } footer: {
                Text("ホーム画面のアイコンが切り替わります。Apple Watch / Mac のアイコンは OS の制約により変更できません。")
            }
        }
        .navigationTitle("アイコン")
        .navigationBarTitleDisplayMode(.inline)
        .alert("変更に失敗しました", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func row(for option: AppIconOption) -> some View {
        let isSelected = option.alternateName == currentAlternateName

        HStack(spacing: OikomiSpacing.m) {
            iconPreview(assetName: option.previewAssetName)

            VStack(alignment: .leading, spacing: 2) {
                Text(option.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(option.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func iconPreview(assetName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Self.iconBackgroundColor,
                            Self.iconBackgroundColor.opacity(0.75),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            Image(assetName)
                .resizable()
                .scaledToFit()
                .padding(8)
        }
        .frame(width: 60, height: 60)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func select(_ option: AppIconOption) {
        guard option.alternateName != currentAlternateName else { return }
        isChanging = true
        let app = UIApplication.shared
        let target = option.alternateName ?? "<primary>"
        print(
            "[Oikomi.icon] supportsAlternateIcons=\(app.supportsAlternateIcons), current=\(app.alternateIconName ?? "<primary>"), target=\(target)"
        )
        app.setAlternateIconName(option.alternateName) { error in
            Task { @MainActor in
                isChanging = false
                if let error {
                    let ns = error as NSError
                    print(
                        "[Oikomi.icon] setAlternateIconName failed: domain=\(ns.domain) code=\(ns.code) desc=\(ns.localizedDescription)"
                    )
                    errorMessage = friendlyErrorMessage(for: ns)
                } else {
                    print("[Oikomi.icon] setAlternateIconName succeeded: \(target)")
                    currentAlternateName = option.alternateName
                    WCSyncBridge.shared.sendIconChange(iconName: option.alternateName)
                }
            }
        }
    }

    /// iOS 26 シミュレータでは setAlternateIconName が常に NSPOSIXErrorDomain で失敗する
    /// (CoreServicesUI のシステム不具合)。`_LSFile` の値は iOS バージョンで変動するため、
    /// targetEnvironment で判定する。実機側は OS エラー全文を残してデバッグに使う。
    private func friendlyErrorMessage(for error: NSError) -> String {
        #if targetEnvironment(simulator)
            if error.domain == NSPOSIXErrorDomain {
                return
                    "iOS シミュレータの不具合により、シミュレータではアイコン切替が動作しません。実機ではご利用いただけます。\n(OS error: \(error.localizedDescription))"
            }
        #endif
        return "\(error.localizedDescription)\n(domain: \(error.domain), code: \(error.code))"
    }
}

#Preview {
    NavigationStack {
        AppIconPickerView()
    }
}
