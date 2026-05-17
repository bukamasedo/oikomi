---
description: docs/SPEC.md の特定セクションを表示（引数なしで目次のみ）
allowed-tools: Read, Bash(grep *), Bash(awk *)
---

`docs/SPEC.md` から指定セクションを抜粋して表示します。

- `$ARGUMENTS` が空: 目次（# 見出し一覧）のみ表示
- `$ARGUMENTS` が数字（例: `4` や `6.2`）: 該当セクション全体を読む
- `$ARGUMENTS` がキーワード: 該当セクションを grep で抽出

ユーザーが「仕様の §4 を見たい」など要望してきた時に使ってください。

手順：

1. 引数がなければ `grep -nE "^#{1,3} " docs/SPEC.md` で目次を表示
2. 引数が数字 N の場合、`docs/SPEC.md` を Read して `## N.` または `### N.` セクションを抜粋
3. 引数がキーワードの場合、`grep -niC 5 "$ARGUMENTS" docs/SPEC.md` で前後5行も含めて表示

必ず原文と差異がないことを確認し、勝手な要約はしないでください。仕様は一次ソースです。
