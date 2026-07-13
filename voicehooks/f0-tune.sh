#!/usr/bin/env bash
# 調声の最深部: f0 曲線を直接編集して合成・再生する。
# 二値アクセントでは出ない「ざぁこ💛」の fall-rise (最終モーラで沈んで跳ねる) を描く。
# フロー: predict_with_duration → estimate_f0 → 曲線編集 → adjustedF0 付き synthesis
#
# 使い方:
#   export SPEAKER_UUID=<speakerUuid> STYLE_ID=<styleId>
#   ./f0-tune.sh <セリフ> [dip] [peak] [split] [speed] [lift]
#     dip   最終モーラの沈み込み係数 (既定 0.84。1.0 で沈みなし=語尾上げのみ)
#     peak  語尾の跳ね上がり係数   (既定 1.25)
#     split 沈み→跳ねの折返し位置  (既定 0.45、モーラ内の相対位置 0..1)
#     speed 話速                   (既定 0.9)
#     lift  全体の底上げ係数       (既定 1.06、甘さの下地)
#   例: ./f0-tune.sh "ざぁこ" 0.84 1.25 0.45        # 標準💛
#       ./f0-tune.sh "ざぁこ" 0.75 1.38 0.50        # 誇張版
#   PROSODY=prosody.json を与えるとアクセント指定 (prosody.sh 出力) と併用できる。
#
# 注意: 一括生成 (generate-voices.sh) は f0 編集に未対応。定番化したい曲線が
# 生まれた日に組み込むこと (それまでは YAGNI)。
set -euo pipefail

: "${SPEAKER_UUID:?環境変数 SPEAKER_UUID を設定してください}"
: "${STYLE_ID:?環境変数 STYLE_ID を設定してください}"
TEXT="${1:?usage: $0 <セリフ> [dip] [peak] [split] [speed] [lift]}"
DIP="${2:-0.84}"
PEAK="${3:-1.25}"
SPLIT="${4:-0.45}"
SPEED="${5:-0.9}"
LIFT="${6:-1.06}"

TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TOOL_DIR/coeiroink-lib.sh"
BASE="$(coeiroink_resolve_base)"

PROSODY_JSON="null"
[ -n "${PROSODY:-}" ] && PROSODY_JSON="$(jq -c . "$PROSODY")"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 1. 時間割付きで一度合成 (モーラごとの wavRange を得る)
jq -n --arg u "$SPEAKER_UUID" --argjson s "$STYLE_ID" --arg t "$TEXT" \
  --argjson sp "$SPEED" --argjson pd "$PROSODY_JSON" \
  '{speakerUuid: $u, styleId: $s, text: $t, speedScale: $sp}
   + (if $pd then {prosodyDetail: $pd} else {} end)' \
  | curl -s -X POST "$BASE/v1/predict_with_duration" -H 'Content-Type: application/json' \
      -d @- -o "$TMP_DIR/pwd.json"

# 2. f0 曲線を抽出
curl -s -X POST "$BASE/v1/estimate_f0" -H 'Content-Type: application/json' \
  -d @"$TMP_DIR/pwd.json" -o "$TMP_DIR/f0.json" </dev/null

# 3. 曲線編集: 全体を lift 倍し、最終モーラ (pau を除く) に fall-rise を描く
jq -c --slurpfile pw "$TMP_DIR/pwd.json" \
  --argjson dip "$DIP" --argjson peak "$PEAK" --argjson sp "$SPLIT" --argjson lift "$LIFT" '
  .f0 as $f | ($f|length) as $n
  | ($pw[0].moraDurations | map(select(.mora != "pau")) | last.wavRange) as $r
  | ($pw[0].moraDurations | last.wavRange.end) as $total
  | (($n / $total) * $r.start | floor) as $fs
  | (($n / $total) * $r.end   | ceil)  as $fe
  | [ range(0; $n) as $i | $f[$i] as $v
      | if $v <= 0 then 0
        else $v * $lift *
          (if $i < $fs then 1.0
           else ((($i - $fs) / ($fe - $fs)) | if . > 1 then 1 else . end) as $t
             | if $t < $sp then 1.0 - (1.0 - $dip) * ($t / $sp)
               else $dip + ($peak - $dip) * (($t - $sp) / (1 - $sp)) end
           end)
        end ]' "$TMP_DIR/f0.json" > "$TMP_DIR/curve.json"

# 4. 編集済み曲線で本合成 (pitch/intonation は曲線に含まれるため素通し)
jq -n --arg u "$SPEAKER_UUID" --argjson s "$STYLE_ID" --arg t "$TEXT" \
  --argjson sp "$SPEED" --argjson pd "$PROSODY_JSON" --slurpfile f0 "$TMP_DIR/curve.json" \
  '{speakerUuid: $u, styleId: $s, text: $t, adjustedF0: $f0[0],
    speedScale: $sp, volumeScale: 1.0, pitchScale: 0.0, intonationScale: 1.0,
    prePhonemeLength: 0.01, postPhonemeLength: 0.01, outputSamplingRate: 44100}
   + (if $pd then {prosodyDetail: $pd} else {} end)' > "$TMP_DIR/body.json"

coeiroink_synth "$BASE" "$(cat "$TMP_DIR/body.json")" "$TMP_DIR/out.wav"
paplay "$TMP_DIR/out.wav"

echo "dip=$DIP peak=$PEAK split=$SPLIT speed=$SPEED lift=$LIFT" >&2
