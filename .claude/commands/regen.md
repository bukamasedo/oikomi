---
description: XcodeGen で project.yml から Oikomi.xcodeproj を再生成
allowed-tools: Bash(xcodegen *), Bash(brew install xcodegen), Bash(which xcodegen)
---

`project.yml` の内容から `Oikomi.xcodeproj` を再生成します。

実行：

```bash
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen が未インストールです。インストールします..."
  brew install xcodegen
fi
xcodegen generate
echo "---"
ls -la Oikomi.xcodeproj 2>/dev/null && echo "✅ 再生成完了" || echo "❌ 生成失敗"
```

`project.yml` を変更した後、または `.xcodeproj` がおかしくなったら都度実行してください。
`.xcodeproj` は gitignore 済みなのでコミット不要です。
