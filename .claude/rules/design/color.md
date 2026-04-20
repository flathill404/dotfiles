# Color

## 方針

- 色指定は `globals.css` 定義のセマンティックトークンのみ使用
- Tailwind 標準パレット(`bg-slate-*` 等)は**使用禁止**
- 色の任意値(`bg-[#ff0000]`)は**完全禁止**
- 汎用キーワード(`white`, `black`, `transparent`, `current`, `inherit`)は許容
- オパシティ修飾子(`bg-primary/50`)は許容
- `dark:` 修飾子は**使用禁止**(非対応プロジェクト)
- 利用可能トークンは `src/app/globals.css` を参照(読み取り専用)

## ⚠️ AI 操作禁止: `src/app/globals.css`

色トークン定義は `globals.css` で**人間が管理する聖域**。
AI は**このファイルを絶対に編集・追加・削除してはならない**。

新トークンが必要な場合:
1. AI は追加を**提案のみ**行う(末尾テンプレ参照)
2. 人間がレビュー・編集
3. 編集後、AI は既存トークンとして利用可能

## 対象プロパティ

色を取る全ユーティリティが対象:
- `bg-*` `text-*` `border-*`
- `ring-*` `ring-offset-*` `outline-*` `shadow-*` `accent-*` `caret-*` `divide-*` `decoration-*`
- `fill-*` `stroke-*`
- `from-*` `to-*` `via-*`(グラデーション)

## 判定フロー

1. 汎用キーワード(`white`/`black`/`transparent`/`current`/`inherit`)→ 許容
2. オパシティ修飾子付きトークン(`bg-primary/50`)→ 許容
3. `globals.css` 定義のセマンティックトークン → 使用可
4. Tailwind 標準パレット → **不可**。既存トークンで代替
5. 色の任意値 → **完全禁止**
6. `dark:` 修飾子 → **不可**
7. 既存トークンで解決不能な真の新規用途 → 「提案発動条件」確認後、提案のみ

## 提案発動条件(AI 向け)

以下を**すべて満たす**ときのみ、トークン追加を提案する:

1. `globals.css` の既存トークンを全確認
2. 意味的に流用可能なトークンが存在しない(下記「誤用マッピング」も確認)
3. 汎用キーワードでも代替不可

疑わしい場合は既存トークンでの代替を優先。

## ルール 1: 生の Tailwind 色パレット禁止

`slate, gray, zinc, neutral, stone, red, orange, amber, yellow, lime, green, emerald, teal, cyan, sky, blue, indigo, violet, purple, fuchsia, pink, rose` をクラス名で直接指定しない。

**理由**: 色の意味がコードから失われ一貫性が崩れる。セマンティックトークンを介することで意味が保たれる。

**検証**:
```bash
rg '\b(bg|text|border|ring|ring-offset|outline|fill|stroke|from|to|via|decoration|shadow|accent|caret|divide)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-' -g '*.{tsx,jsx,ts,js}' -g '!src/app/globals.css'
```

✅
```tsx
<button className="bg-primary text-primary-foreground">
<div className="border-border bg-muted">
<button className="focus-visible:ring-2 focus-visible:ring-ring">
```

❌
```tsx
<button className="bg-blue-500 text-white">
<div className="border-gray-200 bg-slate-50">
<button className="dark:bg-slate-900">
```

### 誤用マッピング

| ❌ やりがち | ✅ 代替 |
|---|---|
| `border-gray-200` / `border-slate-200` | `border-border` |
| `bg-gray-50` / `bg-slate-50` | `bg-muted` |
| `text-gray-500` / `text-slate-500` | `text-muted-foreground` |
| `bg-white`(カード背景) | `bg-card` / `bg-background` |
| `text-gray-900` / `text-black`(本文) | `text-foreground` |
| `bg-red-500` / `text-red-600`(エラー) | `bg-destructive` / `text-destructive` |
| `text-white`(ボタン内文字) | `text-primary-foreground` |
| `ring-blue-500` | `ring-ring` |

## ルール 2: 色の任意値は完全禁止

`bg-[#ff0000]`, `text-[rgb(...)]`, `border-[hsl(...)]` 等は一切使用しない。

**理由**: 色は「なぜこの値か」の正当化が困難。デザインシステム外の色混入はリブランディング等のコストを爆発させる。

**検証**:
```bash
rg '\b(bg|text|border|ring|ring-offset|outline|fill|stroke|from|to|via|decoration|shadow|accent|caret|divide)-\[(#|rgb|hsl|oklch|oklab|color)' -g '*.{tsx,jsx,ts,js}'
```

❌
```tsx
<div className="bg-[#3b82f6]">
<span className="text-[rgb(59,130,246)]">
```

## ルール 3: 汎用キーワードは許容

- `white` / `black` — オーバーレイ・装飾・ボーダー等
- `transparent` — 透明
- `current` — `currentColor` 継承
- `inherit` — 継承

✅
```tsx
<div className="bg-black/50">               {/* オーバーレイ */}
<svg className="fill-current" />            {/* 親の text-* 継承 */}
<div className="border-transparent">
<div className="shadow-black/20">           {/* 装飾影 */}
```

## トークン一覧(参考)

実際の定義は `globals.css` 参照(本一覧は更新遅れあり)。

**shadcn/ui 標準**:
`background` / `foreground` / `card` / `card-foreground` / `popover` / `popover-foreground` / `primary` / `primary-foreground` / `secondary` / `secondary-foreground` / `muted` / `muted-foreground` / `accent` / `accent-foreground` / `destructive` / `destructive-foreground` / `border` / `input` / `ring`

**プロジェクト独自(追加予定含む)**:
`success` / `success-foreground` / `warning` / `warning-foreground`(他は `globals.css` 参照)

## 新規トークン追加 提案テンプレート

```
【色トークン追加提案】

用途: フォーム送信成功時のバナー背景
提案トークン名: --success / --success-foreground
提案値(例): oklch(0.72 0.15 145) / oklch(0.98 0.01 145)
使用箇所: src/components/feature/submit-banner.tsx
理由: primary は情報系 CTA に予約、成功状態との視覚的区別が必要
既存で代替不可な理由: destructive は否定的文脈用で意味的に不適切
```

## 検証用 grep 集

```bash
# 生の Tailwind パレット(globals.css 除外)
rg '\b(bg|text|border|ring|ring-offset|outline|fill|stroke|from|to|via|decoration|shadow|accent|caret|divide)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-' -g '*.{tsx,jsx,ts,js}' -g '!src/app/globals.css'

# 色の任意値
rg '\b(bg|text|border|ring|ring-offset|outline|fill|stroke|from|to|via|decoration|shadow|accent|caret|divide)-\[(#|rgb|hsl|oklch|oklab|color)' -g '*.{tsx,jsx,ts,js}'

# dark: 修飾子
rg '\bdark:' -g '*.{tsx,jsx,ts,js}'

# globals.css の変更検知
git diff --name-only | grep -E 'globals\.css$'
```