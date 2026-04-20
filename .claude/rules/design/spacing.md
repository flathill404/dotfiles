# Spacing

## 方針

- spacing 系ユーティリティは**標準スケール**のみ使用
- 任意値(`p-[13px]`)は**理由コメント必須**
- ただし `src/components/ui/` 配下はすべて許容(コメント不要)
- v4 動的 spacing(`p-13` 等の定義外整数)は**非推奨**

## 標準スケール

`0, px, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 72, 80, 96`

負値プレフィックス(`-m-4`)も同スケール準拠。

## 適用対象

spacing スケールを取るユーティリティ全般:
- `p-*` `m-*`(論理プロパティ `ps-` `pe-` `ms-` `me-` 含む)
- `gap-*` `space-x-*` `space-y-*`
- `w-*` `h-*` `size-*` `min-w-*` `max-w-*` `min-h-*` `max-h-*`
- `inset-*` `top-*` `right-*` `bottom-*` `left-*`
- `translate-x-*` `translate-y-*`
- `scroll-m-*` `scroll-p-*`

## 判定フロー

1. `src/components/ui/` 配下 → **すべて許容・終了**
2. 標準スケール内の値 → そのまま使用
3. 非標準整数値(`p-13`)を使いたい → 任意値 `p-[52px]` + 理由コメントに変換
4. 任意値を使う → **直前行に理由コメント必須**
5. コメントが「仕様」「必要」等の空文言 → 不可。具体根拠を書く

## ルール1: 非標準整数値禁止

非標準整数値(`p-13`, `gap-22` 等)は使わない。必要なら任意値 + 理由コメントで書く。

**検証**: 目視。PR 差分は下記で抽出。

```bash
git diff --name-only | xargs rg -o '\b-?(p|m|gap|space|w|h|size|min-w|max-w|min-h|max-h|inset|top|right|bottom|left|translate-[xy]|scroll-[mp])(s|e|t|r|b|l|x|y)?-[a-z0-9.\[\]]+'
```

✅ `<div className="p-4 gap-6">`
❌ `<div className="p-13 gap-22">`

## ルール2: 任意値は理由コメント必須

- **位置**: 対象行の直前 1 行
- **形式**: JSX 内 `{/* ... */}`、その他 `// ...`
- **質**: 「値の出所」または「標準で代替不可な具体理由」を含む(次項参照)

**検証**:

```bash
rg '(p|m|gap|space|w|h|size|min-w|max-w|min-h|max-h|inset|top|right|bottom|left|translate-[xy]|scroll-[mp])(s|e|t|r|b|l|x|y)?-\[' -g '!src/components/ui/**'
```

✅
```tsx
{/* デザイン: 外部ロゴ余白と揃えるため 7px 固定(標準 8px だと 1px ずれる) */}
<div className="mt-[7px]">
```

❌
```tsx
<div className="mt-[7px]">                    {/* コメントなし */}
{/* 仕様のため */} <div className="mt-[7px]">  {/* 空文言 */}
```

## ルール3: `src/components/ui/` 配下はセーフ

配下のファイルは任意値・非標準値すべて許容、コメント不要。shadcn/ui と外部デザイン受領物の upstream diff を最小化するため。

配下**外**へのコピペ時はルール2に従う。

## 理由コメントの質基準

**必須要素(いずれか)**:
- 値の**出所**(Figma、外部仕様、計測値)
- 標準で**代替不可な具体理由**(視覚ズレ、既存要素整合)

❌ `{/* 仕様のため */}` `{/* 必要 */}` `{/* デザイン通り */}`
✅ `{/* Figma: ヘッダーロゴのベースライン揃えに 7px */}`
✅ `{/* 計測: 画像の視覚中央合わせで 2px オフセット */}`
✅ `{/* 標準 8px だと隣接アイコンと視覚的にズレるため */}`

## 状態プレフィックスの扱い

`hover:` `focus:` `dark:` 等の状態プレフィックス付き任意値にも本ルールを適用。

✅
```tsx
{/* デザイン: hover時に 2px 浮かせる */}
<button className="hover:-translate-y-[2px]">
```

## 典型パターン

**カード**
```tsx
<div className="rounded-lg border p-6">
  <h3 className="mb-2">Title</h3>
  <p>Body</p>
</div>
```

**フォーム行**
```tsx
<div className="flex flex-col gap-4">
  <label className="flex flex-col gap-1.5">
    <span>Name</span>
    <input className="h-10 px-3" />
  </label>
</div>
```

**アイコン + テキスト**
```tsx
<button className="inline-flex items-center gap-2 px-4 py-2">
  <Icon className="size-4" />
  <span>Action</span>
</button>
```

**セクション区切り**
```tsx
<main className="flex flex-col gap-16 py-12">
  <section>...</section>
</main>
```