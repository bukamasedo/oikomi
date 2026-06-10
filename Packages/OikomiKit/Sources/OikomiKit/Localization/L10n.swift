import Foundation

/// OikomiKit 内で生成するユーザー向け文字列をローカライズするヘルパー。
///
/// OikomiKit は UI を持たないが、コーチング文言・enum の表示名など
/// 「ユーザーに見える文字列」をビジネスロジック層で組み立てる。これらは
/// SwiftUI の `LocalizedStringKey` 自動解決の外側にあるため、明示的に
/// SPM リソースバンドル（`.module`）の String Catalog を参照して解決する。
///
/// 補間（`loc("\(n) 日連続")` 等）は `String.LocalizationValue` がそのまま扱い、
/// String Catalog 側で `%lld` / `%@` プレースホルダとして抽出される。
func loc(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}
