# voicehooks

Claude Code のフックイベントを COEIROINK のキャラクター音声で読み上げさせる道具箱。
現在の声主は「リリンちゃん」(メスガキ style)。将来は独立ツール化する予定のため、
stow パッケージにせず自己完結させている。

## 構成

| ファイル | 役割 |
|---|---|
| `announce-hook-cached.sh` | フック本体。イベント名に対応するキャッシュ済み mp3 を再生 |
| `hook-lines.json` | 台本。セリフと調声値 (`{text, speed, pitch, intonation, volume, styleId, prosody}`) |
| `generate-voices.sh` | 台本を一括合成して `voices/<声主>/` に保存 |
| `tune-voice.sh` | 一行だけ合成して試聴 (調声ループの主役) |
| `prosody.sh` | モーラ単位アクセント (GUI のイントネーション欄相当) の取得・編集用 |
| `f0-tune.sh` | f0 曲線の直接編集。「ざぁこ💛」の fall-rise はこれでしか出ない |
| `coeiroink-lib.sh` | 接続解決と合成の共通処理 |
| `voices/ririn/` | 生成済み音声 (派生物。台本から再生産可能) |

## 配線

- `~/.claude/hooks/` 内の同名ファイルはここへのシンボリックリンク (settings.json が参照)
- `~/.claude/voices` → `voices/` のシンボリックリンク (announce が読む)
- 声主の切替は環境変数 `CLAUDE_VOICE_SET` (既定 `ririn`)

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
