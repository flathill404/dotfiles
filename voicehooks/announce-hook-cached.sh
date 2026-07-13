#!/usr/bin/env bash
# Claude Code hook: 発火イベント名に対応するキャッシュ済み wav を再生する。
# 合成は行わない (generate-voices.sh で事前生成しておくこと)。
INPUT="$(cat)"

# hook 実行環境は PATH が最小構成のことがあるため jq に依存しない
EVENT="$(printf '%s' "$INPUT" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -z "$EVENT" ] && exit 0

printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$EVENT" >> "$HOME/.claude/hook-events.log"

# 声主フォルダの切替: CLAUDE_VOICE_SET=<name> (既定 ririn)
SND="$HOME/.claude/voices/${CLAUDE_VOICE_SET:-ririn}/$EVENT.mp3"
if [ -f "$SND" ] && command -v paplay >/dev/null 2>&1; then
  # hook をブロックしないようバックグラウンド再生 (WSLg PulseAudio 経由)
  (paplay "$SND" >/dev/null 2>&1 &)
fi
exit 0
