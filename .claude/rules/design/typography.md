# Typography

## 方針

- `font-family` は `globals.css` 定義のセマンティックトークン(`font-sans` / `font-mono` / `font-serif`)のみ使用
- `text-*` サイズは Tailwind 標準スケール(`text-xs` 〜 `text-9xl`)のみ、**任意値完全禁止**
- `text-*` のうち**色指定**(`text-primary` 等)は Color ルール、**サイズ指定**(`text-base` 等)は本ルールが扱う
- `font-*`(weight)は Tailwind 標準を自由に使用、任意値禁止
- `leading-*` は標準トークンのみ、`loose` は理由コメント必須、任意値**完全禁止**
- `tracking-*` は原則未指定、和文要素での変更禁止、任意値**完全禁止**
- `italic` は和文要素で使用禁止(合成斜体で品質低下)
- `dark:` 修飾子は**使用禁止**

## ⚠️ AI 操作禁止

フォント関連定義は AI も人間も手を入れない前提:

- `src/app/globals.css`(フォント関連 `@theme` 変数)
- `src/app/layout.tsx`(`next/font` 設定)

`layout.tsx` も対象なのは、`next/font` のフォント読み込み設定がここに集約されているため。追加が必要な場合は末尾テンプレで**提案のみ**。

## 「和文要素」の判定(AI 向け)

次のいずれかに該当する要素は「和文要素」とみなす:

- 子コンテンツが日本語を含む、または日本語が入る可能性がある変数・翻訳キー
- 本文・見出し・ラベル・説明文など業務アプリの主要 UI
- 明確に欧文のみと判定できない場合

**デフォルトは和文扱い**。欧文専用ルール(`tracking-wide` / `italic`)は、UPPERCASE 装飾や英語固有名詞の短いバッジなど、**明らかに欧文のみ**と判定できる場合に限る。

## 判定フロー(プロパティ別)

### `font-*`(family)
- `font-sans` / `font-mono` / `font-serif` のみ許容
- 任意値(`font-['Inter']` 等)禁止

### `text-*`(size)
- `text-xs` 〜 `text-9xl` のみ許容
- 任意値完全禁止。特殊サイズが必要なら `text-sm` / `text-base` で代替を試み、どうしても不可なら人間に相談

### `font-*`(weight)
- `font-thin` 〜 `font-black` 自由に使用
- 数値任意値(`font-[650]`)禁止
- **注意**: `next/font` で読み込んでいないウェイトは faux bold で品質低下

### `leading-*`
- 許容: `none` / `tight` / `snug` / `normal` / `relaxed`
- `loose` は理由コメント必須
- 任意値完全禁止
- **shadcn/ui や `<body>` で既定値が継承される場合は書かない**。上書き時のみ指定

### `tracking-*`
- 原則未指定(Tailwind デフォルト = `normal` = 0)
- 和文要素での指定は禁止
- 欧文大文字(UPPERCASE)要素でのみ `tracking-wide` / `tracking-widest` 許容
- 任意値完全禁止

### `italic`
- 和文要素では使用禁止(合成斜体になる)
- 欧文のみの要素で使用可

### `uppercase` / `capitalize` / `lowercase`
- 和文要素では効果なし、冗長なので書かない
- 欧文要素でのみ使用

### `dark:`
- 使用禁止

## 許容値一覧

### フォントサイズ

| クラス | rem | px(16px base) |
|---|---|---|
| `text-xs` | 0.75rem | 12px |
| `text-sm` | 0.875rem | 14px |
| `text-base` | 1rem | 16px |
| `text-lg` | 1.125rem | 18px |
| `text-xl` | 1.25rem | 20px |
| `text-2xl` | 1.5rem | 24px |
| `text-3xl` | 1.875rem | 30px |
| `text-4xl` | 2.25rem | 36px |
| `text-5xl` | 3rem | 48px |
| `text-6xl` | 3.75rem | 60px |
| `text-7xl` 〜 `text-9xl` | … | 72 / 96 / 128px |

### 行高

| クラス | 倍率 | 用途 |
|---|---|---|
| `leading-none` | 1 | ボタン・ラベル等の1行要素 |
| `leading-tight` | 1.25 | 見出し |
| `leading-snug` | 1.375 | 見出し(やや広め) |
| `leading-normal` | 1.5 | 本文・UI(既定) |
| `leading-relaxed` | 1.625 | 長めの本文 |
| `leading-loose` | 2 | 非推奨(広すぎ、理由コメント必須) |

## 改行制御(推奨)

- `text-balance`: 見出し・短いタイトル(自動的に改行バランス調整)
- `text-pretty`: 本文(孤立行・未亡人行を削減)

```tsx
<h2 className="text-2xl font-bold text-balance">長めの見出しテキスト</h2>
<p className="text-pretty">本文...</p>
```

## 要素→クラス 早見表

| 要素 | `text-*` | `font-*`(weight) | `leading-*` |
|---|---|---|---|
| 本文(`<p>`) | `text-base` | `font-normal` | `leading-normal` or `relaxed` |
| 補足・キャプション | `text-sm` | `font-normal` | `leading-normal` |
| ヘルパーテキスト(入力欄下) | `text-xs` or `text-sm` | `font-normal` | `leading-normal` |
| UI ラベル | `text-sm` | `font-medium` | `leading-none` or `normal` |
| ボタン | `text-sm` | `font-medium` or `semibold` | `leading-none` |
| フォーム input 内テキスト | `text-sm` or `text-base` | `font-normal` | `leading-normal` |
| テーブル cell | `text-sm` | `font-normal` | `leading-normal` |
| トースト・通知 | `text-sm` | `font-normal` | `leading-normal` |
| バッジ・チップ | `text-xs` | `font-medium` | `leading-none` |
| h3 | `text-lg` | `font-semibold` | `leading-snug` |
| h2 | `text-2xl` | `font-semibold` or `bold` | `leading-tight` |
| h1 | `text-3xl` 〜 `text-4xl` | `font-bold` | `leading-tight` |
| 欧文大文字バッジ | `text-xs` | `font-medium` | `leading-none` + `tracking-wide` |

`tracking-*` は欧文大文字要素を除き原則未指定。見出し階層の具体スタイルは Component ルールで最終確定。

## Good / Avoid

✅
```tsx
<p className="text-base">本文</p>
<h2 className="text-2xl font-bold leading-tight text-balance">見出し</h2>
<button className="text-sm font-medium leading-none">ボタン</button>
<span className="uppercase tracking-wide text-xs font-medium">NEW</span>
```

❌
```tsx
<p className="text-[13px]">                        {/* 任意値禁止 */}
<p className="leading-[1.8]">                      {/* 任意値禁止 */}
<p className="tracking-wide">和文に tracking 不可</p>
<p className="italic">和文に italic 不可</p>
<p className="dark:text-white">dark: 不可</p>
<h2 className="uppercase">日本語見出し</h2>        {/* 和文に効果なし */}
```

## 新規フォント・ウェイト追加の提案テンプレート

```
【フォント追加提案】

種別: 新規フォントファミリー / 既存ファミリーへのウェイト追加
対象: 例) font-serif 新設 / Noto Sans JP weight 300 追加
使用箇所: src/components/feature/xxx.tsx
理由: (なぜ必要か)
既存で代替不可な理由: (font-sans / font-mono で不足する具体理由)
```

## 検証用 grep 集

```bash
# font-family の任意値
rg "\bfont-\['" -g '*.{tsx,jsx,ts,js}'

# text-* のサイズ任意値(数値 / rem / var / calc 等)
rg '\btext-\[(?:-?[0-9]|var\(|calc\(|small|large)' -g '*.{tsx,jsx,ts,js}'

# font-* の数値任意値(ウェイト)
rg '\bfont-\[[0-9]' -g '*.{tsx,jsx,ts,js}'

# leading の任意値 or loose
rg '\bleading-(loose|\[)' -g '*.{tsx,jsx,ts,js}'

# tracking の任意値
rg '\btracking-\[' -g '*.{tsx,jsx,ts,js}'

# italic(和文要素での使用を目視確認)
rg '\bitalic\b' -g '*.{tsx,jsx,ts,js}'

# 和文要素での uppercase/capitalize/lowercase(目視で和文判定)
rg '\b(uppercase|capitalize|lowercase)\b' -g '*.{tsx,jsx,ts,js}'

# dark: 修飾子
rg '\bdark:' -g '*.{tsx,jsx,ts,js}'
```