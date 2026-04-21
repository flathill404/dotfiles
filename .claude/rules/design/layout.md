# Layout

## 方針

- **レスポンシブ修飾子(`sm:` / `md:` / `lg:` / `xl:` / `2xl:` / `max-*:`)は完全禁止**(デスクトップオンリー業務アプリ)
- Tailwind の `container` クラスは使用しない(全画面幅レイアウトのため)
- Flex と Grid は用途で使い分け
- 子要素の間隔は原則 `gap-*`、`space-x-*` / `space-y-*` は使用禁止
- `z-index` は標準スケール(`z-0` 〜 `z-40`)のみ、`z-50` 以上は shadcn/ui 専用
- `top-*` / `right-*` / `bottom-*` / `left-*` / `inset-*` の値スケールは Spacing ルールに準ずる
- `grid-cols-[160px_1fr]` 等の構造記述用任意値は許容(値の任意化ではなく構造定義のため)
- `dark:` 修飾子は使用禁止

## ルール 1: レスポンシブ修飾子は完全禁止

**検証**:
```bash
rg '\b(sm|md|lg|xl|2xl|max-sm|max-md|max-lg|max-xl|max-2xl):' -g '*.{tsx,jsx,ts,js}'
```

❌
```tsx
<div className="flex flex-col md:flex-row">
```

## ルール 2: Flex と Grid の使い分け

### 判定フロー

1. 2次元配置(行×列両方制御) → **Grid**
2. 子要素のサイズを均等 / 比率で揃えたい → **Grid**
3. それ以外 → **Flex**

### 要素別の選択(頻出パターン)

| 要素 | 選択 |
|---|---|
| サイドバー + メイン | Flex |
| ヘッダー(ロゴ / ナビ / ユーザー) | Flex |
| ボタン群(同一行) | Flex |
| アイコン + テキスト | Flex |
| カード格子 | Grid |
| フォーム(ラベル:入力の整列) | Grid |
| ダッシュボードの KPI タイル | Grid |
| データテーブル | **`<table>` 要素を使う**(Grid で代替しない) |

### Flex 子要素のサイズ制御

| クラス | 用途 |
|---|---|
| `flex-1` | 残り領域を埋める(メインコンテンツ等) |
| `shrink-0` | 縮まない(サイドバー・アイコン・固定幅要素) |
| `grow` | 明示的に伸ばす |
| (未指定) | 中身サイズで決定 |

典型: `<aside className="w-64 shrink-0">` + `<main className="flex-1">`

### Grid の構造記述

`grid-cols-[160px_1fr]` のような構造記述の任意値は許容(色・spacing の任意値禁止とは別扱い)。

### ✅ Good

```tsx
<div className="flex items-center gap-2">
  <Button>保存</Button>
  <Button variant="outline">キャンセル</Button>
</div>

<div className="grid grid-cols-3 gap-4">
  {items.map(item => <Card key={item.id} {...item} />)}
</div>

<div className="grid grid-cols-[160px_1fr] items-center gap-4">
  <label>名前</label><Input />
</div>
```

### ❌ Avoid

```tsx
{/* Flex で格子を作らない(行高が揃わない / 最終行が左寄せ) */}
<div className="flex flex-wrap gap-4">
  {items.map(item => <Card className="w-1/3" />)}
</div>
```

## ルール 3: 子要素の間隔は `gap-*`、`space-*` は禁止

**理由**: `space-*` は margin ベースで `first/last-child` に癖、`flex-wrap` で破綻、`divide-*` と併用不可。

**検証**:
```bash
rg '\bspace-[xy]-' -g '*.{tsx,jsx,ts,js}'
```

✅ `<div className="flex gap-2">` / `<div className="grid gap-4">`
❌ `<div className="flex space-x-2">`

## ルール 4: z-index は標準スケール + shadcn/ui 分離

### 階層マップ(自前要素)

| 値 | 用途 |
|---|---|
| `z-0` | デフォルト |
| `z-10` | 同一平面での重ね順調整(カード内オーバーレイ等) |
| `z-20` | ページ内 sticky(テーブルヘッダ等) |
| `z-30` | アプリレベル sticky(ヘッダー / サイドバー) |
| `z-40` | 自前のオーバーレイ背景 |

**`z-50` 以上は shadcn/ui 専用**。自前要素では使用しない。フローティング要素(トースト等)は shadcn/ui の `Toaster` 等を使う。

### スタッキングコンテキストの注意

`z-*` は同じスタッキングコンテキスト内でのみ効く。親が `transform` / `opacity-*` / `filter` 等を持つと、子の `z-40` が外の `z-30` より後ろに来ることがある。`z-*` を付けても前面に来ない場合は**祖先のスタッキングコンテキストを疑う**。

### 制約

- 任意値(`z-[9999]` 等)禁止
- `z-auto` の積極使用は非推奨(明示的な `z-0` を推奨)

**検証**:
```bash
rg '\bz-\[' -g '*.{tsx,jsx,ts,js}'
```

✅ `<header className="sticky top-0 z-30 bg-background">`
❌ `<div className="z-[9999]">` / `<header className="z-[100]">`

## ルール 5: Position の使用と事故パターン

### `relative`

子の `absolute` の基準点を作る。**`absolute` の子を持つ場合は親に必ず付ける**。

### `absolute`

直近の positioned 祖先を基準に配置。

**事故**: 親に `relative` がないと予期しない祖先(最悪 `<body>`)に吸着。

### `fixed`

ビューポート基準で固定。

**事故**: 祖先に `transform` / `filter` / `perspective` / `will-change: transform` があると、ビューポートではなくその祖先基準になる(CSS 仕様)。ルート直下に置くのが安全。

### `sticky`

スクロール時に指定位置で固定。

**事故**:
- 親に `overflow: hidden/auto` があると、**その親の範囲内でしか効かない**
- 高さ制限のない親では効かない
- `top-*` / `left-*` 等の位置指定必須

業務アプリのテーブルヘッダ・サイドバー見出し等で積極活用。

### ✅ Good

```tsx
{/* Badge 配置: relative 親を忘れない */}
<div className="relative">
  <Image />
  <span className="absolute top-2 right-2 ...">NEW</span>
</div>

{/* テーブルヘッダ固定 */}
<div className="overflow-auto">
  <table>
    <thead className="sticky top-0 z-20 bg-background">...</thead>
  </table>
</div>
```

## ルール 6: Overflow の扱い

### ⚠️ 高さ制限のないスクロール領域は無効

`overflow-y-auto` は親に高さ制限がないと発動しない。

❌ `<div className="overflow-y-auto">`
✅ `<div className="max-h-96 overflow-y-auto">`
✅ `<div className="h-screen overflow-y-auto">`

### 頻出パターン

```tsx
{/* 独立スクロール領域 */}
<aside className="h-screen overflow-y-auto">

{/* データテーブル: 両方向スクロール */}
<div className="overflow-auto"><table>...</table></div>

{/* 1行省略 */}
<p className="truncate">{longText}</p>

{/* 複数行省略 */}
<p className="line-clamp-3">{longText}</p>
```

### 注意点

- `overflow-hidden` は問答無用で切り落とす。テキストには `truncate` / `line-clamp-*` を優先
- `overflow-auto` + `sticky` の親子関係は、sticky がその overflow コンテナ内でのみ効く(ルール5参照)

## ルール 7: 表示/非表示の制御

- 条件分岐で要素が不要: **JSX の条件レンダリング**(`{condition && <Element />}`)を優先
- レイアウト上スペースは保持したい場合のみ: `invisible` / `visible`
- DOM は残すが見えなくする: `hidden`(`display: none`、レイアウトも消える)

## 基本パターン集

### サイドバー + メイン(アプリケーションの基本形)

```tsx
<div className="flex h-screen">
  <aside className="w-64 shrink-0 overflow-y-auto border-r">
    <nav>...</nav>
  </aside>
  <main className="flex flex-1 flex-col overflow-hidden">
    <header className="sticky top-0 z-30 border-b bg-background">...</header>
    <div className="flex-1 overflow-auto p-6">
      {/* ページコンテンツ */}
    </div>
  </main>
</div>
```

### 中央寄せレイアウト(ログイン・エラー画面等)

```tsx
<div className="flex min-h-screen items-center justify-center">
  <div className="w-full max-w-sm">{/* フォーム */}</div>
</div>
```

### データテーブル(ヘッダ固定 + 両方向スクロール)

```tsx
<div className="overflow-auto rounded border">
  <table className="w-full">
    <thead className="sticky top-0 z-20 bg-muted">
      <tr>...</tr>
    </thead>
    <tbody>...</tbody>
  </table>
</div>
```

### フォーム(ラベル:入力の整列)

```tsx
<div className="grid grid-cols-[160px_1fr] items-center gap-4">
  <label>ユーザー名</label>
  <Input />
  <label>メールアドレス</label>
  <Input />
</div>
```

### カード格子

```tsx
<div className="grid grid-cols-3 gap-4">
  {items.map(item => <Card key={item.id} {...item} />)}
</div>
```

## 検証用 grep 集

```bash
# レスポンシブ修飾子
rg '\b(sm|md|lg|xl|2xl|max-sm|max-md|max-lg|max-xl|max-2xl):' -g '*.{tsx,jsx,ts,js}'

# space-x-* / space-y-*
rg '\bspace-[xy]-' -g '*.{tsx,jsx,ts,js}'

# z-index の任意値
rg '\bz-\[' -g '*.{tsx,jsx,ts,js}'

# container クラス
rg '\bcontainer\b' -g '*.{tsx,jsx,ts,js}'

# dark: 修飾子
rg '\bdark:' -g '*.{tsx,jsx,ts,js}'
```