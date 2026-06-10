---
description: 版上げ → commit → タグ → push を自動実行（trunk-based + タグ運用）
allowed-tools: Bash(git *), Bash(grep *), Bash(xcodegen *), Bash(gh *), Read, Edit
---

Oikomi のリリース手順を実行します。**バージョンはタグで表す**運用（CLAUDE.md「Git / ブランチ運用」参照）。

`$ARGUMENTS` = 新しいマーケ版（例 `0.1.1`）。省略時はマーケ版を据え置き、ビルド番号だけ +1。

必ず以下の順で進め、**push の直前に内容を要約してユーザーに確認**を取ること（破壊的操作のため）。

### 1. 前提チェック
- `main` ブランチにいるか確認。違えば中断して案内
- `git status` がクリーンか確認。未コミット変更があれば中断して案内
- `git fetch --prune` で最新化し、`main` が `origin/main` と同期しているか確認

### 2. 現在の版を読む
`project.yml` から現在値を取得：
```bash
grep -nE "CFBundleShortVersionString|CFBundleVersion" project.yml
```
- 現マーケ版 = `CFBundleShortVersionString`（4 箇所すべて同値のはず）
- 現ビルド番号 = `CFBundleVersion`

### 3. 新しい版を決める
- 新マーケ版 = `$ARGUMENTS`（指定時）/ 現状維持（未指定時）
- 新ビルド番号 = 現ビルド番号 + 1（**必ず増やす。リセット禁止**）

### 4. project.yml を更新
`CFBundleShortVersionString` と `CFBundleVersion` の **4 ターゲット分すべて**を新値に書き換える（Edit の replace_all を活用）。値が 4 箇所で揃っていることを確認。

### 5. xcodeproj 再生成
`xcodegen generate` を実行（project.yml 変更を Info.plist 生成物へ反映）。生成された変更を `git status` で確認。

### 6. コミット
```bash
git add -A
git commit -m "chore(release): vX.Y.Z (build N)"
```

### 7. 確認 → タグ → push
ここで「マーケ版 X.Y.Z / ビルド N / タグ vX.Y.Z+N を main に push する」と要約し、**ユーザーの承認を得てから**実行：
```bash
git tag -a "vX.Y.Z+N" -m "Release X.Y.Z (build N)"
git push origin main
git push origin "vX.Y.Z+N"
```

### 8. GitHub Release（任意）
ユーザーが希望すれば、直近の変更点をまとめて作成：
```bash
gh release create "vX.Y.Z+N" --title "vX.Y.Z (build N)" --notes "..."
```

### 完了後
- 次に Xcode で Archive → App Store Connect へアップロードする旨を案内する
- このコマンドは**バージョン確定とタグ付けまで**。実際のビルド/アップロードは手動作業
