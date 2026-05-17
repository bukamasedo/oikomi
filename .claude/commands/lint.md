---
description: swift-format lint で違反箇所を検出（修正はしない）
allowed-tools: Bash(xcrun *), Bash(swift-format *)
---

`.swift-format` 設定に違反するコードを検出します。修正はしません。

実行：

```bash
xcrun swift-format lint --recursive \
  --configuration .swift-format \
  App Packages/OikomiKit/Sources Packages/OikomiKit/Tests
```

検出された違反を整理して報告してください。自動修正したい場合は `/format` を使用するよう案内してください。
