---
description: iOS シミュレータ向けに Oikomi アプリをビルド（xcbeautify 経由でエラー抜粋）
allowed-tools: Bash(xcodebuild *), Bash(xcbeautify *), Bash(xcrun *)
---

iOS シミュレータ向けに Oikomi スキームをビルドします。失敗時はエラー行のみ抜粋表示してください。

`$ARGUMENTS` が指定されていればスキーム名として使用、未指定なら `Oikomi` を使います。

実行：

```bash
SCHEME="${ARGUMENTS:-Oikomi}"
xcodebuild build \
  -project Oikomi.xcodeproj \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  | xcbeautify --quiet 2>/dev/null || xcodebuild build \
    -project Oikomi.xcodeproj \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS Simulator' \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|warning:|FAILED" | head -50
```

`Oikomi.xcodeproj` が存在しなければ、最初に `xcodegen generate` を実行するよう案内してください。
