#!/usr/bin/env bash
# 調教用: 一行だけ合成してその場で再生する。気に入る値が見つかったら、最後に
# 出力される JSON を hook-lines.json の該当イベントに貼り、generate-voices.sh で
# 一括再生成する。
#
# 使い方:
#   export SPEAKER_UUID=<speakerUuid> STYLE_ID=<styleId>
#   ./tune-voice.sh <セリフ> [speed] [pitch] [intonation] [volume]
#   例: ./tune-voice.sh "きゃはは！ざぁ〜こ！" 1.35 0.03 1.4
#
# モーラ単位のアクセント (GUI のイントネーション欄相当) も指定できる:
#   PROSODY=prosody.json ./tune-voice.sh "..." ...   (prosody.sh で生成・編集した detail JSON)
#
# パラメータの目安:
#   speed      話速。1.0=標準、一括生成の既定は 1.25
#   pitch      音高。0.0 基準、±0.05 でさりげなく、±0.15 で別人
#   intonation 抑揚の振れ幅。1.0 基準、煽りは 1.3〜1.5、けだるげは 0.8〜0.9
#   volume     音量。1.0 基準
#
# speakerUuid / styleId の一覧:
#   curl -s $COEIROINK_URL/v1/speakers | jq -r '.[] | .speakerName + " " + .speakerUuid + " " + ([.styles[] | .styleName + "=" + (.styleId|tostring)] | join(" "))'
set -euo pipefail

: "${SPEAKER_UUID:?環境変数 SPEAKER_UUID を設定してください}"
: "${STYLE_ID:?環境変数 STYLE_ID を設定してください}"
TEXT="${1:?usage: $0 <セリフ> [speed] [pitch] [intonation] [volume]}"
SPEED="${2:-1.25}"
PITCH="${3:-0.0}"
INTONATION="${4:-1.0}"
VOLUME="${5:-1.0}"

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKS_DIR/coeiroink-lib.sh"
BASE="$(coeiroink_resolve_base)"

TMP_WAV="$(mktemp --suffix=.wav)"
trap 'rm -f "$TMP_WAV"' EXIT

PROSODY_JSON="null"
[ -n "${PROSODY:-}" ] && PROSODY_JSON="$(jq -c . "$PROSODY")"

BODY="$(jq -n --arg u "$SPEAKER_UUID" --argjson s "$STYLE_ID" --arg t "$TEXT" \
  --argjson sp "$SPEED" --argjson pi "$PITCH" --argjson in "$INTONATION" --argjson vo "$VOLUME" \
  --argjson pd "$PROSODY_JSON" \
  '{speakerUuid: $u, styleId: $s, text: $t, speedScale: $sp, volumeScale: $vo,
    pitchScale: $pi, intonationScale: $in,
    prePhonemeLength: 0.01, postPhonemeLength: 0.01, outputSamplingRate: 44100}
   + (if $pd then {prosodyDetail: $pd} else {} end)')"

coeiroink_synth "$BASE" "$BODY" "$TMP_WAV"
paplay "$TMP_WAV"

# 採用時に hook-lines.json へそのまま貼れる形で出力
jq -n --arg t "$TEXT" --argjson s "$STYLE_ID" --argjson sp "$SPEED" \
  --argjson pi "$PITCH" --argjson in "$INTONATION" --argjson vo "$VOLUME" \
  --argjson pd "$PROSODY_JSON" -c \
  '{text: $t, speed: $sp, pitch: $pi, intonation: $in, volume: $vo, styleId: $s}
   + (if $pd then {prosody: $pd} else {} end)'
