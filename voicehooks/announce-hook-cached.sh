#!/usr/bin/env bash
# Claude Code hook: 発火イベント名に対応するキャッシュ済み wav を再生する。
# 合成は行わない (generate-voices.sh で事前生成しておくこと)。
INPUT="$(cat)"

# hook 実行環境は PATH が最小構成のことがあるため jq に依存しない
EVENT="$(printf '%s' "$INPUT" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -z "$EVENT" ] && exit 0

printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$EVENT" >> "$HOME/.claude/hook-events.log"

# 声主フォルダの切替: CLAUDE_VOICE_SET=<name> (既定 ririn)
# <Event>-<n>.mp3 のバリエーション群からランダムに1本選ぶ (旧形式 <Event>.mp3 も候補)。
# hook 環境は PATH が最小のことがあるため、乱数は bash 組み込みの RANDOM を使う。
DIR="$HOME/.claude/voices/${CLAUDE_VOICE_SET:-ririn}"
files=()
for f in "$DIR/$EVENT".mp3 "$DIR/$EVENT"-*.mp3; do
  [ -f "$f" ] && files+=("$f")
done
if [ "${#files[@]}" -gt 0 ] && command -v paplay >/dev/null 2>&1; then
  SND="${files[RANDOM % ${#files[@]}]}"
  # hook をブロックしないようバックグラウンド再生 (WSLg PulseAudio 経由)
  (paplay "$SND" >/dev/null 2>&1 &)
fi
exit 0
