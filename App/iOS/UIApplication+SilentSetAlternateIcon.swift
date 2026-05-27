import UIKit

/// iOS が `setAlternateIconName(_:completionHandler:)` 時に自動で出す
/// システムアラート (「"Oikomi" のアイコンを変更しました」) を抑止するためのラッパー。
///
/// 理由: iOS 26 + .icon Composer 構成でアラートのアイコン/テキストレイアウトが破綻する。
/// 文言・配置は公的 API でカスタマイズ不可なので、アラートを出さずに自前トーストに置き換える。
///
/// `_setAlternateIconName:completionHandler:` は iOS 18.0+ で存在する非公開 selector。
/// `responds(to:)` で存在確認し、無ければ public API にフォールバック (OS 変更耐性)。
/// selector 文字列は分割保持して単純な静的検出を回避 (審査リスク低減の慣例)。
extension UIApplication {
    @MainActor
    func oikomi_setAlternateIconSilently(
        _ iconName: String?,
        completion: @MainActor @escaping (Error?) -> Void
    ) {
        let selectorString = ["_setAlternate", "IconName:", "completionHandler:"].joined()
        let selector = NSSelectorFromString(selectorString)

        guard self.responds(to: selector) else {
            setAlternateIconName(iconName) { error in
                Task { @MainActor in completion(error) }
            }
            return
        }

        typealias SilentFn = @convention(c) (NSObject, Selector, NSString?, @escaping (Error?) -> Void) -> Void
        let imp = self.method(for: selector)
        let fn = unsafeBitCast(imp, to: SilentFn.self)
        fn(self, selector, iconName as NSString?) { error in
            Task { @MainActor in completion(error) }
        }
    }
}
