---
description: iPhone シミュレータで Oikomi を起動
allowed-tools: Bash(xcodebuild *), Bash(xcrun *), Bash(simctl *), Bash(open *)
---

iPhone シミュレータで Oikomi アプリをビルドして起動します。

`$ARGUMENTS` でシミュレータ名を指定可能（デフォルト: `iPhone 17 Pro`）。

実行：

```bash
DEVICE="${ARGUMENTS:-iPhone 17 Pro}"

# シミュレータを起動
open -a Simulator
xcrun simctl boot "$DEVICE" 2>/dev/null || true

# ビルド + インストール + 起動
xcodebuild \
  -project Oikomi.xcodeproj \
  -scheme Oikomi \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build install 2>&1 | tail -20

# 起動
BUNDLE_ID="com.shuhirouchi.oikomi"
xcrun simctl launch "$DEVICE" "$BUNDLE_ID" || echo "起動失敗（既にインストール済みか確認）"
```

シミュレータ一覧は `xcrun simctl list devices available` で確認できます。
