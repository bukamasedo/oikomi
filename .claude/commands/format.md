---
description: swift-format で App/ と Packages/OikomiKit/Sources/ を一括整形
allowed-tools: Bash(xcrun *), Bash(swift-format *)
---

リポジトリ内の Swift ソースを `.swift-format` 設定に従って整形します。

実行：

```bash
xcrun swift-format format --in-place --recursive \
  --configuration .swift-format \
  App Packages/OikomiKit/Sources Packages/OikomiKit/Tests
```

変更があったファイルを `git status --short` で確認してください。
