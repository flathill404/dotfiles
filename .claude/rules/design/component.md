# Component

## 方針

- shadcn/ui を積極採用、**足りない汎用 UI のみ自作**
- コンポーネントは 3 層構造(`ui/` / `composite/` / `custom/`)で配置、依存方向は一方向
- shadcn 本体の直接編集は許容(軽微な調整に限る)。編集時も Color / Spacing ルールに従う
- `cn()` は条件付きクラス適用・外部 `className` マージに使用
- `cva` は `ui/` と `composite/` のみで使用、`custom/` では使わない
- Next.js だが SPA 構成(原則 Client Component)、`"use client"` は境界のみに付与
- shadcn の `asChild` パターンを活用、不用意なラッパーを作らない
- クラス名順序は `prettier-plugin-tailwindcss` に委譲、手動整理しない

## ディレクトリ構成

```
src/components/
├── ui/         # shadcn + 自作プリミティブ(最小単位、ドメイン非依存)
├── composite/  # ui の組み合わせ(ドメイン非依存)
└── custom/     # ドメイン知識を持つコンポーネント(フラット)
```

### 依存方向

```
ui/  ←  composite/  ←  custom/
```

- `ui/` は他層を import しない(最下層)
- `composite/` は `ui/` のみ import 可
- `custom/` は `ui/` と `composite/` を import 可、ドメインロジック持ち込み可
- **逆方向の import は禁止**

### ファイル命名規約

| ディレクトリ | 命名 | 例 |
|---|---|---|
| `ui/` | 小文字 + kebab-case | `button.tsx` / `status-dot.tsx` |
| `composite/` | PascalCase | `SearchBar.tsx` / `DataTable.tsx` |
| `custom/` | PascalCase | `UserCard.tsx` / `OrderDetail.tsx` |

ファイル名が kebab-case でも、export 名は PascalCase:

```tsx
// ui/status-dot.tsx
export function StatusDot({ ... }) { ... }
```

## ルール 1: shadcn/ui の採用判断

### 判定フロー

1. shadcn に同等機能がある? → **使う**
2. バリアント値(`variant` / `size`)の追加のみ? → **shadcn 本体を拡張**(ルール 4)
3. 新しい Prop / 新しい挙動を追加? → **派生コンポーネントを `ui/` に作成**(ルール 4)
4. 全く新しい汎用 UI? → **`ui/` に自作**(例: `Spinner` / `StatusDot` / `Divider` / `KBD`)
5. Radix UI ラップで実現できる新プリミティブ? → **`ui/` に自作**

### ❌ やらない

- shadcn に既に存在するものの再実装
- shadcn 既存コンポーネントの `variant` / `size` を増やすだけのラッパー(本体を直接拡張)

### ✅ Good

```
ui/
├── button.tsx          # shadcn
├── input.tsx           # shadcn
├── spinner.tsx         # 自作(shadcn に無い)
└── status-dot.tsx      # 自作
```

## ルール 2: composite の抽出基準

### 抽出判定(いずれかを満たす)

- 同一の `ui/` 組み合わせパターンが **3 箇所以上**で使われている
- 2 箇所でも、JSX 規模が大きい(目安 **10 行超**)
- ドメイン非依存かつ、将来確実に再利用される見込み(理由を PR またはコメントで明記)

**迷ったら抽出しない**。早すぎる抽象化は YAGNI 違反。

### ✅ Good

```tsx
// composite/SearchBar.tsx(3 箇所以上で使用)
export function SearchBar({ onSearch }: Props) {
  return (
    <div className="flex gap-2">
      <Input placeholder="検索..." />
      <Button onClick={onSearch}>検索</Button>
    </div>
  );
}
```

### ❌ Avoid

- 1 回しか使わないのに composite 化
- テキストや文言違いだけの差分を Props 化して composite 化(過剰抽象)

## ルール 3: custom の責務と composite との判定

### 配置

`custom/` はフラット。ドメイン別サブディレクトリは作らない。

### フラット配置の境界

ファイル数が **30 件を超えた**時点で、ドメイン別ディレクトリへの分割を検討する。分割時もファイル命名規則は維持(PascalCase)。

### 責務

- ドメインロジック(データ整形・バリデーション等)の持ち込み可
- API 呼び出し、状態管理、ページ固有の文言を持ってよい

### composite と custom の判定

以下のいずれかに該当すれば **custom**:

- コンポーネント名にドメイン概念を含む(`User*` / `Order*` / `Login*` 等)
- 特定のデータ型・API・バリデーションスキーマに依存
- プロジェクト外で再利用する想定がない

それ以外(汎用パターン)は **composite**:

- `SearchBar` / `DataTable` / `PageHeader` / `EmptyState` 等
- Props でカスタマイズでき、どのドメインでも使える

## ルール 4: shadcn 本体のカスタマイズ

### 直接編集 OK(`ui/` の shadcn 本体を編集)

- 色・spacing 等のスタイル微調整
- 既存バリアント(`variant` / `size`)の追加・調整
- 軽微な挙動修正(focus ring 微調整など)

### 派生コンポーネント化すべき(別ファイルを `ui/` に作成)

- **挙動の追加**(例: `LoadingButton` = Button + loading 状態)
- **全面カスタマイズ**(見た目を大幅に変える)
- **ドメイン固有化**(`custom/` や `composite/` に新規作成)

### 編集時もデザインルールに従う

shadcn 本体を直接編集する場合も、**Color ルール(セマンティックトークン使用)・Spacing ルール(標準スケール使用)に従う**。

`ui/` 特例は「任意値・非標準値の許容」だけであり、セマンティックトークンの代わりに生の色を使ってよいという意味ではない。

```tsx
// ✅ shadcn 本体編集(ブランド色に調整、セマンティックトークン経由)
// ui/button.tsx
const buttonVariants = cva(
  "... bg-primary text-primary-foreground ...",
  { variants: { ... } }
);

// ❌ 生の色を使うのは ui/ でも禁止
// "... bg-slate-900 text-white ..."
```

### 派生例

```tsx
// ui/loading-button.tsx
import { Button } from "./button";
import { Spinner } from "./spinner";

export function LoadingButton({ loading, children, ...props }) {
  return (
    <Button disabled={loading} {...props}>
      {loading && <Spinner />}
      {children}
    </Button>
  );
}
```

## ルール 5: Radix UI の `asChild` パターン

shadcn/ui の多くのコンポーネント(Button, Dialog trigger 等)は `asChild` prop をサポートする。子要素を別のコンポーネント(例: Next.js の `<Link>`)に差し替えつつ、親のスタイル・挙動を引き継ぐ。

**ラッパー用の新コンポーネントを作る前に `asChild` で足りないか検討する**。

### ✅ Good

```tsx
<Button asChild>
  <Link href="/users">ユーザー一覧</Link>
</Button>
```

### ❌ Avoid

```tsx
{/* Link の挙動が消える */}
<Button>
  <Link href="/users">ユーザー一覧</Link>
</Button>
```

## ルール 6: `cn()` ユーティリティ

### 使うケース

- **条件付きクラス適用**: `cn("base", isActive && "bg-primary")`
- **外部から渡される `className` のマージ**: `cn("default", className)`

### 使わないケース

- 静的な文字列のみ(`cn("foo bar")` は書かず `"foo bar"` と直接書く)

### ✅ Good

```tsx
<div className={cn("rounded border p-4", isActive && "bg-primary text-primary-foreground")}>

export function Card({ className, ...props }) {
  return <div className={cn("rounded border bg-card p-6", className)} {...props} />;
}
```

## ルール 7: `cva` バリアント定義

### 使うディレクトリ

**`ui/` と `composite/` のみ**。`custom/` では使わない。

### 理由

- `cva` はバリアント(再利用される形)を定義するための仕組み
- `custom/` は 1 箇所でしか使わないコンポーネント中心。バリアント化する意味が薄い(YAGNI)
- `custom/` で条件分岐は `cn()` で十分

### ✅ Good

```tsx
// ui/status-dot.tsx
const statusDotVariants = cva(
  "inline-block rounded-full",
  {
    variants: {
      size: { sm: "size-2", md: "size-3", lg: "size-4" },
      tone: { success: "bg-success", warning: "bg-warning", destructive: "bg-destructive" },
    },
    defaultVariants: { size: "md", tone: "success" },
  }
);
```

### ❌ Avoid

```tsx
// custom/UserCard.tsx で cva を使う(1 箇所のみの過剰抽象)
const userCardVariants = cva(...);

// 代わりに cn() で:
<div className={cn("rounded border p-4", user.isPremium && "border-primary")}>
```

## ルール 8: Client Component の境界

### 原則

SPA 構成のため Client Component が中心。ただし `"use client"` は**境界となるファイルにのみ付ける**。

### `"use client"` を付ける場所

- **ページエントリーポイント**(`app/**/page.tsx` の Client 化が必要な場合)
- **明示的に Client 境界にしたいコンポーネント**(ドキュメント目的)

### `"use client"` を付けない場所

- Client Component の子として呼ばれるだけのコンポーネント(親経由で自動的に Client 扱い)
- `ui/` / `composite/` / `custom/` 配下の大多数のコンポーネント

### 理由

- 全ファイルに付けると冗長でノイズになる
- 境界を上位で引くことで、Server Component への移行時の改修範囲が明確になる

### Server Component として残す候補

- ルートレイアウト(`app/layout.tsx`)
- メタデータ生成のみを行うページ

## ルール 9: クラス名の順序・整理

**手動でクラス名を整列しない**。`prettier-plugin-tailwindcss` に委譲する。

### 理由

- 手動整列はレビュー時に不毛な議論を生む
- Prettier プラグインが Tailwind 公式推奨の順序で自動整列する

### 未導入時の提案

`prettier-plugin-tailwindcss` が未導入の場合、AI は人間に導入を提案する(末尾「提案テンプレート」参照)。

## よくある判断(Q&A)

**Q: 同じ `className` を持つ Button が 3 箇所以上にある。**
→ 内容(テキスト・アイコン)が同じなら composite 化、違うなら **shadcn 本体に新 variant を追加**。文言だけ違う場合は composite 化しない(冗長)。

**Q: `Button + Input` の組み合わせが 3 箇所あるが、プレースホルダーもボタン文言も違う。**
→ 構造が同じなら composite 化(例: `SearchBar`)。Props でテキストを受け取る設計にする。

**Q: `UserProfileCard` と `OrderSummaryCard` が共通のスタイルを持っている。**
→ スタイルのみの共通化なら **shadcn の Card バリアント**で対応。ドメインごとのコンポーネントは分けたまま。

**Q: `Button` に `<Link>` を入れたい。**
→ `asChild` を使う。ラッパーコンポーネントは不要(ルール 5)。

**Q: `LoginForm` は composite と custom どちら?**
→ **custom**。「ログイン」という具体ドメインを持ち、特定のバリデーション・API に依存するため。

## 提案テンプレート

### コンポーネント構造変更

```
【コンポーネント構造変更提案】

種別: shadcn 本体の大幅改変 / 外部ライブラリ導入 / ディレクトリ構造変更 / 他
対象: (ファイルパスまたは構造)
変更内容: (何を変えるか)
影響範囲: (影響するコンポーネント数 / 他)
理由: (なぜ必要か、既存ルールで対応できない理由)
```

### prettier-plugin-tailwindcss 導入(未導入時)

```
【prettier-plugin-tailwindcss 導入提案】

目的: Tailwind クラス名の自動整列
コマンド: npm install -D prettier-plugin-tailwindcss
.prettierrc 追記: { "plugins": ["prettier-plugin-tailwindcss"] }
理由: 手動整列を避け、クラス順序に関するレビュー議論を削減する
```

## 検証用 grep 集

```bash
# ui/ → composite or custom の逆方向 import
rg "from\s+['\"](?:.*/)?(composite|custom)/" -g 'src/components/ui/**/*.{tsx,ts}'

# composite/ → custom の逆方向 import
rg "from\s+['\"](?:.*/)?custom/" -g 'src/components/composite/**/*.{tsx,ts}'

# custom/ での cva 使用
rg '\b(cva|class-variance-authority)\b' -g 'src/components/custom/**/*.{tsx,ts}'

# `"use client"` の氾濫チェック(ui/ composite/ での使用)
rg '^\s*["\x27]use client["\x27]' -g 'src/components/{ui,composite}/**/*.{tsx,ts}'
```