# voicehooks

Claude Code のフックイベントを COEIROINK のキャラクター音声で読み上げさせる道具箱。
現在の声主は「リリンちゃん」(メスガキ style)。将来は独立ツール化する予定のため、
stow パッケージにせず自己完結させている。

## 構成

| ファイル | 役割 |
|---|---|
| `hook-lines.json` | 台本。値は文字列 / オブジェクト (`{text, speed, pitch, intonation, volume, styleId, prosody}`) / それらの配列 (バリエーション、現行は85セット×10本=850行・全行明示調声値) |
| `generate-voices.sh` | 台本を一括合成して `voices/<声主>/<Event>-<n>.mp3` に保存 (生成前に旧 mp3 を掃除) |
| `tune-voice.sh` | 一行だけ合成して試聴 (調声ループの主役) |
| `prosody.sh` | モーラ単位アクセント (GUI のイントネーション欄相当) の取得・編集用 |
| `f0-tune.sh` | f0 曲線の直接編集。「ざぁこ💛」の fall-rise はこれでしか出ない |
| `coeiroink-lib.sh` | 接続解決と合成の共通処理 |
| `voices/ririn/` | 生成済み音声 (派生物。台本から再生産可能) |

## 配線

再生スクリプトは置かない。settings.json の各フックエントリに再生コマンドを直接埋め込み、
`"async": true` で非同期実行させる (Claude Code はプロセス終了を待たない):

```json
{ "type": "command",
  "command": "paplay ~/.claude/voices/ririn/<セット名>-$(shuf -i 1-10 -n 1).mp3",
  "async": true }
```

- 各セットは常に 10 本 (`-1`〜`-10`) という前提で番号を直接抽選する
  (`$RANDOM` は POSIX sh に無く無言で 0 に化けるので `shuf -i` を使う)
- チルダは引用符の中では展開されないため、パスは裸で書く
  (セット名は英数字とドットのみ・空白なし、なので安全)
- async では exit code は全無視 (PreToolUse の exit 2 ブロックも無効。音声には元々無用)
- timeout は書かない (async の既定 600 秒で十分。最長ボイスは 16 秒。
  明示するなら 17 秒未満は禁物 — 長台詞の尻が切れる)
- `~/.claude/voices` → `voices/` のシンボリックリンク (再生コマンドが読む)
- 再生側は `voices/ririn/` 直書き (声主はひとりしかいない — YAGNI。増えた日に書き換える)。
  `CLAUDE_VOICE_SET` は generate-voices.sh の出力先切替としてのみ残る
- 調声ツール群 (`tune-voice.sh` など) の `~/.claude/hooks/` symlink はそのまま

### ツール別・状況別セリフ (matcher)

settings.json 側で matcher により分岐し、エントリごとに専用セット名を埋め込む。

| イベント | 専用セット (matcher の対象) |
|---|---|
| PreToolUse / PostToolUse | `.Bash` `.Edit` `.Read` `.Web` `.Agent` `.Ask` `.Plan` `.Skill` `.Workflow` `.Todo` `.MCP` (ツール名、MCP は `mcp__.*`) |
| PostToolUseFailure | `.Bash` `.Edit` `.Web` `.Read` `.Agent` `.MCP` (ツール名) |
| PermissionDenied | `.Bash` `.Edit` (拒否されたツール) |
| SessionStart | `.resume` `.clear` `.compact` (起動方式。startup は素のセット) |
| SessionEnd | `.logout` `.prompt_input_exit` (去り際。clear/resume は SessionStart 側が歌うので除外) |
| Notification | `.idle_prompt` `.permission_prompt` `.agent_needs_input` (通知タイプ) |
| SubagentStart / SubagentStop | `.Explore` `.Plan` `.guide` (エージェント種別) |
| PreCompact | `.manual` `.auto` (圧縮の引き金) |
| StopFailure | `.rate_limit` `.overloaded` `.billing_error` `.max_output_tokens` `.server_error` `.authentication_failed` (エラー種別) |

matcher の挙動 (2026-07-14 にヘッドレス実験で確認):

- 英数字と `|` のみ → ツール名の完全一致パイプリスト。それ以外の文字を含むと正規表現
- 複数エントリが同時マッチすると**全部発火する** (二重再生)。そのため「その他」は
  負の先読み `^(?!(Bash|…)$).*` で専用組を除外する (JS RegExp なので先読み可)

### 同時発火するイベントは声を持たせない

matcher を整えても、**別イベント同士**が同じ瞬間に発火して二重再生になる
(2026-07-15 にログで確認)。冗長な観測者はエントリごと外してある:

| 瞬間 | 声を残した側 | 黙らせた側 |
|---|---|---|
| ツール完了 | `PostToolUse.*` | `PostToolBatch`、`CwdChanged` |
| compact 完了 | `SessionStart.compact` | `PostCompact` (`PreCompact` は単独発火なので残置) |
| resume・プロンプト送信 | `SessionStart.resume` / `UserPromptSubmit` | `InstructionsLoaded` (同秒に2回発火することもある) |
| 許可プロンプト | `Notification.permission_prompt` (数秒遅れて単独発火) | `PermissionRequest` 全部 (PreToolUse と同秒発火のため) |
| /clear・resume | `SessionStart.clear` / `.resume` | `SessionEnd` の同 reason (先読みで除外) |
| サブエージェント完了 | `SubagentStop.*` | `Notification.agent_completed` (先読みで除外) |

mp3 は焼いてあるので、エントリを書き戻せばいつでも復活する。

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

生成: COEIROINK v2 (Windows 側 :50032、WSL からはゲートウェイ経由自動解決)、jq、ffmpeg。
再生: paplay、shuf (coreutils)。
