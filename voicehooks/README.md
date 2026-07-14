# voicehooks

Claude Code のフックイベントを COEIROINK のキャラクター音声で読み上げさせる道具箱。
現在の声主は「リリンちゃん」(メスガキ style)。将来は独立ツール化する予定のため、
stow パッケージにせず自己完結させている。

## 構成

| ファイル | 役割 |
|---|---|
| `announce-hook-cached.sh` | フック本体。イベントの変種群 `<Event>-<n>.mp3` からランダムに1本再生 |
| `hook-lines.json` | 台本。値は文字列 / オブジェクト (`{text, speed, pitch, intonation, volume, styleId, prosody}`) / それらの配列 (バリエーション、現行は53セット×10本=530行・全行明示調声値) |
| `generate-voices.sh` | 台本を一括合成して `voices/<声主>/<Event>-<n>.mp3` に保存 (生成前に旧 mp3 を掃除) |
| `tune-voice.sh` | 一行だけ合成して試聴 (調声ループの主役) |
| `prosody.sh` | モーラ単位アクセント (GUI のイントネーション欄相当) の取得・編集用 |
| `f0-tune.sh` | f0 曲線の直接編集。「ざぁこ💛」の fall-rise はこれでしか出ない |
| `coeiroink-lib.sh` | 接続解決と合成の共通処理 |
| `voices/ririn/` | 生成済み音声 (派生物。台本から再生産可能) |

## 配線

- `~/.claude/hooks/` 内の同名ファイルはここへのシンボリックリンク (settings.json が参照)
- `~/.claude/voices` → `voices/` のシンボリックリンク (announce が読む)
- 声主の切替は環境変数 `CLAUDE_VOICE_SET` (既定 `ririn`)

### ツール別・状況別セリフ (matcher)

settings.json 側で matcher により分岐し、引数で専用セット名を渡す
(例: `announce-hook-cached.sh PreToolUse.Bash`)。専用 mp3 が未生成なら素のイベント名にフォールバックする。

| イベント | 専用セット (matcher の対象) |
|---|---|
| PreToolUse / PostToolUse | `.Bash` `.Edit` `.Read` `.Web` `.Agent` `.Ask` (ツール名) |
| PostToolUseFailure / PermissionRequest | `.Bash` `.Edit` `.Web` (ツール名) |
| SessionStart | `.resume` `.clear` `.compact` (起動方式。startup は素のセット) |
| Notification | `.idle_prompt` (通知タイプ) |
| StopFailure | `.rate_limit` (エラー種別) |

matcher の挙動 (2026-07-14 にヘッドレス実験で確認):

- 英数字と `|` のみ → ツール名の完全一致パイプリスト。それ以外の文字を含むと正規表現
- 複数エントリが同時マッチすると**全部発火する** (二重再生)。そのため「その他」は
  負の先読み `^(?!(Bash|…)$).*` で専用組を除外する (JS RegExp なので先読み可)
- command のシェル文字列に書いた引数はそのまま届く

## 調声ワークフロー

```bash
export SPEAKER_UUID=cb11bdbd-78fc-4f16-b528-a400bae1782d STYLE_ID=92  # リリンちゃん/メスガキ
./tune-voice.sh "きゃはは！ざぁこ！" 1.35 0.03 1.4   # text speed pitch intonation
# 気に入った値を hook-lines.json に書き戻して:
SPEED=1.2 INTONATION=1.3 ./generate-voices.sh $SPEAKER_UUID $STYLE_ID
```

## 調声の知見

- 「〜」は休符に化けて韻律が千切れる。伸ばしは「ー」で書く
- 抑揚 (intonation) が煽り声の主役。1.3〜1.5。けだるげは 0.8 台
- アクセントの 0/1 で足りない甘さ (💛) は `f0-tune.sh` の fall-rise で描く
- メスガキ文法: 語尾の念押し疑問 (ねえ？でしょ？)、反復 (ざこざこ)、笑いの前置き (きゃはっ)

## 依存

COEIROINK v2 (Windows 側 :50032、WSL からはゲートウェイ経由自動解決)、jq、ffmpeg、paplay
