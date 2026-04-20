# Coding Rules

このディレクトリはプロジェクトのコーディング規約 index。
実装・レビュー時は該当カテゴリのルールを参照すること。

## 基本原則

- **推奨ベース**: 規約は強制ではなく推奨。逸脱は許容するが、**理由を明記**する
- **逸脱時の手順**: 対象コードの直近にコメントで理由を記載する
- **例外ディレクトリ**: `src/components/ui/` 配下など、ルールごとに免除対象が定義される場合がある(各ルール参照)
- **一貫性優先**: 個別の最適解より、プロジェクト全体で揃っていることを重視する

## ルール一覧

### Design

見た目・レイアウトに関する規約。

- [Spacing](./design/spacing.md) — 余白・サイズ指定の標準スケールと任意値の扱い
- [Color](./design/color.md) — 色トークンとセマンティックカラーの使い分け
- [Typography](./design/typography.md) — フォントサイズ・ウェイト・行間
- [Layout](./design/layout.md) — Flex / Grid / Container の使用方針
- [Component](./design/component.md) — shadcn/ui の拡張・独自コンポーネントの設計指針

<!-- 将来追加予定(実装時に uncomment)
### React
Hooks, Server / Client Components, state 管理

### Next.js
App Router, Route Handler, Metadata, Caching

### Testing
Playwright, Vitest, Storybook
-->

## 運用

- 既存ルールの改訂・新規ルール追加は PR ベースで行う
- 新規カテゴリを追加する場合は本 README のルール一覧にもリンクを追加する