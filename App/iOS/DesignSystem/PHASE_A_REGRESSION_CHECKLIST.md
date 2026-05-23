# Phase A: iPhone リデザイン 手動リグレッションチェックリスト

実行手順: `/sim-run` で iPhone 17 Pro シミュレータで起動し、以下を順に検証。
各項目に ✅ / ❌ をつける形で結果を残す。

## ホーム

- [ ] 進行中セッションがあれば Resume カードが先頭に表示される
- [ ] StreakRing に連続記録日数が表示・アニメーション
- [ ] StatTile に今週のセッション数・今週ボリュームが正しく出る
- [ ] TodayConditionCard が Pro 状態に応じて HRV/RHR/睡眠 ↔ Pro lock を切り替える
- [ ] コーチング 3 件まで横スクロールで表示（Pro のみ）
- [ ] 直近 PR の HighlightCard が tap で ExerciseDetailView へ遷移
- [ ] 今週のボリューム mini chart が正しく描画

## トレーニング（開始前）

- [ ] クイック開始ボタンがグラデーションで表示
- [ ] ルーティンカードが 2 列グリッドに並ぶ
- [ ] ルーティンを tap で startSession が動く
- [ ] 長押し contextMenu で編集 / 削除
- [ ] Toolbar `+` で RoutineEditorView 起動
- [ ] ルーティンがない場合 OikomiEmptyState が出る
- [ ] Pro ゲートに引っかかった場合 ProUpgradeSheet が出る（Free で 4 個目）

## トレーニング（進行中）

- [ ] 経過時間と完了/計画セット数の Hero カード
- [ ] 種目カードに completed/total chip
- [ ] InlineSetRow の checkmark tap で markSetCompleted、RestTimerCard が起動
- [ ] swipeActions でセット削除
- [ ] 種目内 + セット追加 → AddSetSheet (planMode)
- [ ] 「種目を追加」点線カード → ExercisePickerSheet
- [ ] 「終了」alert → 完了 → HealthKit 書き込み + Live Activity 終了
- [ ] レストタイマー終了で haptic + 通知

## AddSetSheet（最重要）

- [ ] 種目カード tap で ExercisePickerSheet
- [ ] 重量 ± ボタンで 2.5kg 単位で増減
- [ ] 重量 ± を長押しで連続加減（加速あり）
- [ ] レップ ± ボタンで 1 単位
- [ ] 直前差分バッジ (前回 +5.0 / ±0 / -2.5) が正しい色で表示
- [ ] 自重種目（measurementType == .bodyweightReps）では重量行が非表示
- [ ] 保存ボタンが画面下端 safeAreaInset に固定、blur 背景
- [ ] 種目未選択時は保存ボタン disabled

## RoutineEditor

- [ ] 既存ルーティンを開くと値が prefill
- [ ] SingleValueSheet が NumericStepperField に置き換わっている
- [ ] 重量 / レップ / セットの編集で値が反映
- [ ] ドラッグハンドルで並べ替え
- [ ] スワイプ削除

## 履歴

- [ ] PeriodSegment（日/週/月/年/全て）で集計が切り替わる
- [ ] 期間サマリーカードに セッション/セット/ボリューム
- [ ] カレンダーのドットがアクティブ日に表示（OikomiColor.brandPrimary）
- [ ] 日付選択で feed フィルタ
- [ ] WorkoutHistoryCard tap で SessionDetailView 遷移

## SessionDetailView

- [ ] Hero header に日時/所要時間/総セット/ボリューム
- [ ] 種目別 ExerciseInSessionCard (readOnly モード) で表示
- [ ] 「もう一度実行（コピー）」CTA で startSessionByCopying
- [ ] 進行中セッションがある場合 alert で阻止

## 分析

- [ ] 4 カテゴリ Picker（推移/コンディション/ボディ/部位別）で切り替え
- [ ] 推移: 週次総ボリューム + 種目別最大重量チャート（Pro のみ、非 Pro は ProLockTile）
- [ ] コンディション: HRV/RHR/睡眠 3 カード + 注意書き（Pro のみ）
- [ ] ボディ: 体重/体脂肪/LBM 3 カード + ヘルスケアリンク（Pro のみ）
- [ ] 部位別: 週セット数バー + ボリューム kg + 凡例（Pro のみ）
- [ ] 自己ベスト一覧で PR 遷移

## ExerciseDetailView

- [ ] Hero カード（種目名 / 部位タグ）
- [ ] PR カードに重量×レップ + 推定1RM + 達成日
- [ ] StatTile 3 枚（セッション/ワーキングセット/総ボリューム）
- [ ] 最大重量推移 Chart（2 点以上で描画）
- [ ] 直近 20 セットの feed

## 設定

- [ ] Pro hero row（グラデーション）tap で ProUpgradeSheet
- [ ] Pro 加入済みなら proAccent 系グラデーションに切り替わる
- [ ] HealthKit 連携・iCloud Toggle・データ削除フローが動く
- [ ] CSV エクスポートが ShareLink で動く（Pro のみ）

## オンボーディング

- [ ] 初回起動で fullScreenCover 表示
- [ ] WelcomeStep: ブランド色アイコンの ZStack
- [ ] HealthKitStep: 「許可」or 「後で設定」
- [ ] RoutinePromptStep: 「はじめる」で markCompleted

## 横断

- [ ] Light / Dark mode 両方で破綻なし
- [ ] Dynamic Type（AX5）で破綻なし
- [ ] VoiceOver で主要要素読み上げ
- [ ] iPad（compact / regular）の表示
- [ ] タブの Workout に進行中セッションでバッジが表示

## ビルド・テスト

- [x] `xcodebuild ... Oikomi` で iOS シミュレータビルド成功（警告ゼロ・新規追加コード）
- [x] `swift test --package-path Packages/OikomiKit` で 84 テスト全成功
- [x] `xcrun swift-format lint -r App/iOS/...` で違反ゼロ

## Phase B / C 着手前の前提

- [ ] iPhone Phase A の PR がマージされている
- [ ] Phase A の `feature/ui-redesign-phase-a-iphone` から派生して Watch ブランチを切る
- [ ] DesignSystem のトークンは Phase B / C でも再利用可能（OS API の差異だけ吸収）
