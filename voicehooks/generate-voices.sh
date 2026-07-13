#!/usr/bin/env bash
# COEIROINK 起動中に一度実行し、hook-lines.json の全セリフを一括合成して
# ~/.claude/voices/<声主>/<イベント名>.mp3 に保存する (実体は dotfiles 管理、リンク経由)。
# 声主フォルダは CLAUDE_VOICE_SET で切替 (既定 ririn。announce-hook-cached.sh と共通)。
# 使い方: ./generate-voices.sh <speakerUuid> <styleId>
#
# hook-lines.json の値は 2 形式:
#   "Event": "セリフ"                                   … 既定パラメータで合成
#   "Event": {"text": "セリフ", "speed": 1.3, ...}      … セリフ単位で上書き (調教用)
# 上書きできるキー: speed / pitch / intonation / volume / styleId / prosody
# (prosody はモーラ単位アクセントの detail JSON。prosody.sh で生成・編集する)
# 個別の試聴・調整は tune-voice.sh で行い、決まった値をここへ書き戻すこと。
#
# 接続先の上書き: COEIROINK_URL=http://<host>:50032 ./generate-voices.sh ...
# 既定値の上書き: SPEED=1.3 INTONATION=1.3 ./generate-voices.sh ...
set -euo pipefail

SPEAKER_UUID="${1:?usage: $0 <speakerUuid> <styleId>}"
STYLE_ID="${2:?usage: $0 <speakerUuid> <styleId>}"
SPEED="${SPEED:-1.25}"
INTONATION="${INTONATION:-1.0}"
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
LINES_JSON="$HOOKS_DIR/hook-lines.json"
CACHE_DIR="$HOME/.claude/voices/${CLAUDE_VOICE_SET:-ririn}"
mkdir -p "$CACHE_DIR"

. "$HOOKS_DIR/coeiroink-lib.sh"
BASE="$(coeiroink_resolve_base)"
echo "COEIROINK: $BASE"

TMP_WAV="$(mktemp --suffix=.wav)"
trap 'rm -f "$TMP_WAV"' EXIT

jq -c --arg u "$SPEAKER_UUID" --argjson s "$STYLE_ID" --argjson sp "$SPEED" --argjson it "$INTONATION" '
  to_entries[]
  | (.value | if type == "string" then {text: .} else . end) as $v
  | {event: .key,
     body: {speakerUuid: $u,
            styleId: ($v.styleId // $s),
            text: $v.text,
            speedScale: ($v.speed // $sp),
            volumeScale: ($v.volume // 1.0),
            pitchScale: ($v.pitch // 0.0),
            intonationScale: ($v.intonation // $it),
            prePhonemeLength: 0.01,
            postPhonemeLength: 0.01,
            outputSamplingRate: 44100}
           + (if $v.prosody then {prosodyDetail: $v.prosody} else {} end)}' "$LINES_JSON" \
| while IFS= read -r row; do
  event="$(jq -r '.event' <<<"$row")"
  printf 'generating: %-22s ... ' "$event"
  if coeiroink_synth "$BASE" "$(jq -c '.body' <<<"$row")" "$TMP_WAV"; then
    ffmpeg -loglevel error -y -i "$TMP_WAV" -codec:a libmp3lame -q:a 4 "$CACHE_DIR/$event.mp3" </dev/null
    echo "OK"
  else
    echo "NG"
  fi
done

# mp3 群を単一アーカイブにもまとめておく (dotfiles 管理用)
# イベント名にスペースは含まれないため ls 展開で問題ない
tar -cf "$CACHE_DIR/voices.tar" -C "$CACHE_DIR" $(cd "$CACHE_DIR" && ls ./*.mp3)

echo "done -> $CACHE_DIR (voices.tar 更新済み)"
