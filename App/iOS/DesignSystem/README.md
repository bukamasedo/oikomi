# Oikomi iOS DesignSystem

Phase A（iPhone）リデザインで導入したデザインシステム。
Apple 純正アプリ（フィットネス / ヘルスケア / リマインダー / メモ・ジャーナル）に並べたときに違和感がないことを目標に、トークンと再利用コンポーネントを揃えた。

## ディレクトリ構造

```
DesignSystem/
├── Tokens/
│   ├── Colors.swift          OikomiColor — セマンティックカラー
│   ├── Typography.swift      OikomiFont  — Dynamic Type 連動フォント
│   ├── Spacing.swift         OikomiSpacing — 8pt グリッド
│   └── Radii.swift           OikomiRadius — コーナー半径
└── Components/
    ├── StatTile.swift                  数値ハイライト 1 枚
    ├── HighlightCard.swift             横長カード（アイコン+ラベル+任意 trailing）
    ├── PeriodSegment.swift             日/週/月/年/All の期間セグメント
    ├── SectionHeader.swift             タイトル+副題+CTA
    ├── WorkoutHistoryCard.swift        履歴 feed の 1 ワークアウト
    ├── InlineSetRow.swift              セッション内 1 セット行
    ├── RestTimerCard.swift             レストタイマーカード (TimelineView)
    ├── CoachingChip.swift              AI コーチング 1 件 (severity ベース)
    ├── ProLockTile.swift               Pro 限定ペイウォール
    ├── StreakRing.swift                連続記録日数の炎リング
    ├── OikomiEmptyState.swift          ContentUnavailableView のブランドラップ
    ├── NumericStepperField.swift       ± ボタン + 長押し連続入力
    ├── RoutineCard.swift               ルーティン選択カード（グリッド）
    └── ExerciseInSessionCard.swift     進行中セッション内の 1 種目カード
```

## ブランドカラー

- **brandPrimary** `#E85D04` — 「追い込み」を表す deep orange
- **brandSecondary** `#FA822B` — グラデーション用の少し明るい派生色
- **proAccent** `#FFB73D` — Pro 機能のアクセント
- セマンティック色（stat*）は SF Symbols / Apple Health の標準色を踏襲

ContentView で `.tint(OikomiColor.brandPrimary)` を設定しているため、子 View では `.tint` を明示しなくても標準コンポーネントがブランド色に従う。

## 画面マッピング（Phase A）

| 画面 | 状態 | 主要コンポーネント |
|---|---|---|
| `ContentView` | タブ装飾更新 | TabView + Badge |
| `HomeView` | 全面リデザイン | StreakRing / StatTile / TodayConditionCard / CoachingChip / HighlightCard / Swift Charts |
| `WorkoutTabView` | 全面リデザイン | RoutineCard グリッド / ExerciseInSessionCard / RestTimerCard / QuickStart ボタン |
| `AddSetSheet` | 全面リデザイン | NumericStepperField × 2 + safeAreaInset 保存ボタン |
| `RoutineEditorView` | 部分リデザイン | SingleValueSheet を NumericStepperField に置換 |
| `ExercisePickerSheet` | 部分リデザイン | OikomiEmptyState 統合 |
| `HistoryView` | 全面リデザイン | PeriodSegment / 期間サマリーカード / カレンダー / WorkoutHistoryCard feed |
| `SessionDetailView` | 全面リデザイン | Hero header / ExerciseInSessionCard (readOnly) / コピー CTA |
| `AnalysisTabView` | 全面リデザイン | 4 カテゴリ Picker / ProLockTile 統一 / Card 化されたチャート |
| `Analysis/*Section` | DS 統合 | Card-based チャート群（VStack で ScrollView 直接配置可） |
| `ExerciseDetailView` | 全面リデザイン | Hero PR card + StatTile + Chart card + 直近セット feed |
| `SettingsTabView` | 部分リデザイン | Pro ヒーローセル（gradient） |
| `OnboardingView` | 部分リデザイン | ブランド色アイコン + ValueRow |
| `TodayConditionCard` | Section→自立カードへ書き換え | 独立カードで ScrollView に配置可能 |

## 新規ファイル

```
App/iOS/DesignSystem/Tokens/{Colors,Typography,Spacing,Radii}.swift
App/iOS/DesignSystem/Components/{StatTile,HighlightCard,PeriodSegment,SectionHeader,
                                  WorkoutHistoryCard,InlineSetRow,RestTimerCard,
                                  CoachingChip,ProLockTile,StreakRing,
                                  OikomiEmptyState,NumericStepperField,
                                  RoutineCard,ExerciseInSessionCard}.swift
```

XcodeGen は `App/iOS` を再帰的にスキャンするので `project.yml` への登録は不要。
新規ファイル追加後は `xcodegen generate` で `.xcodeproj` を再生成する。

## リデザイン後の境界（再確認）

UI 書き換え時に **触ってよい**：
- View 層・画面遷移・SwiftUI Modifier
- 既存 Repository public API の呼び出し方
- `@Query` 結果の表現
- `ProGate.*` フラグの参照
- Swift Charts の描画

UI 書き換え時に **触ってはいけない**：
- `Packages/OikomiKit/` 配下のロジック（Repository / Model / Coaching / Health / Sync / SubscriptionManager）
- SwiftData `@Model` のプロパティ
- `WCSyncBridge` の send/receive・envelope 形式
- `WatchHealthSession` の HK セッション順序
- `WorkoutActivityAttributes.ContentState` のフィールド名
- バンドル ID / Signing / entitlements

## Phase B / C で扱うもの

このリポジトリの Phase A スコープは iPhone のみ。Watch / Widgets のリデザインは別 PR で対応する（プラン: `~/.claude/plans/ui-imperative-scroll.md`）。

## リグレッションチェックリスト

`PHASE_A_REGRESSION_CHECKLIST.md` を参照。
