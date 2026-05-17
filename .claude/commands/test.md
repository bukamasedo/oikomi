---
description: OikomiKit のユニットテストを実行
allowed-tools: Bash(swift test*), Bash(swift build*)
---

OikomiKit（共有ビジネスロジック）のユニットテストを Swift Package Manager で実行します。

実行：

```bash
cd Packages/OikomiKit && swift test
```

`$ARGUMENTS` でフィルタ指定があればテスト対象を絞り込めます：

```bash
cd Packages/OikomiKit && swift test --filter "$ARGUMENTS"
```

UI ターゲット側のテスト（XCTest with iOS Simulator）は `xcodebuild test` が必要ですが、まずは `swift test` で純粋ロジックを高速検証してください。
