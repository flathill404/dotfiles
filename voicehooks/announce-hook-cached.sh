#!/usr/bin/env bash
# Claude Code hook: 発火イベント名に対応するキャッシュ済み mp3 を再生する。
# 合成は行わない (generate-voices.sh で事前生成しておくこと)。
# 引数 $1 で専用セット名を指定できる (settings.json の matcher 付きエントリ用。
# 例: announce-hook-cached.sh PreToolUse.Bash)。専用セットが未生成のうちは
# 素のイベント名にフォールバックするので、台本より先に配線しても黙らない。
INPUT="$(cat)"

# hook 実行環境は PATH が最小構成のことがあるため jq に依存しない
EVENT="$(printf '%s' "$INPUT" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -z "$EVENT" ] && exit 0

printf '%s %s%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$EVENT" "${1:+ ($1)}" >> "$HOME/.claude/hook-events.log"

# 声主フォルダの切替: CLAUDE_VOICE_SET=<name> (既定 ririn)
# <Set>-<n>.mp3 のバリエーション群からランダムに1本選ぶ (旧形式 <Set>.mp3 も候補)。
# hook 環境は PATH が最小のことがあるため、乱数は bash 組み込みの RANDOM を使う。
DIR="$HOME/.claude/voices/${CLAUDE_VOICE_SET:-ririn}"
files=()
for name in ${1:+"$1"} "$EVENT"; do
  for f in "$DIR/$name".mp3 "$DIR/$name"-*.mp3; do
    [ -f "$f" ] && files+=("$f")
  done
  [ "${#files[@]}" -gt 0 ] && break
done
if [ "${#files[@]}" -gt 0 ] && command -v paplay >/dev/null 2>&1; then
  SND="${files[RANDOM % ${#files[@]}]}"
  # hook をブロックしないようバックグラウンド再生 (WSLg PulseAudio 経由)
  (paplay "$SND" >/dev/null 2>&1 &)
fi
exit 0
