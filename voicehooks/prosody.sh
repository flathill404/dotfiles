#!/usr/bin/env bash
# 調教用: テキストのモーラ分解とアクセント推定 (GUI のイントネーション欄と同じもの) を
# 取得する。stdout に prosodyDetail としてそのまま使える JSON、stderr に一覧表を出す。
#
# 使い方:
#   ./prosody.sh "むりでしょ、ざぁ〜こ" > prosody.json
#   (prosody.json の accent を 0/1 で編集: 1=高, 0=低。配列の入れ子がアクセント句)
#   PROSODY=prosody.json ./tune-voice.sh "むりでしょ、ざぁ〜こ" 1.25 0.0 1.25
#   確定したら hook-lines.json の該当エントリに "prosody": [...] として貼る。
set -euo pipefail

TEXT="${1:?usage: $0 <テキスト>}"

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$HOOKS_DIR/coeiroink-lib.sh"
BASE="$(coeiroink_resolve_base)"

DETAIL="$(jq -n --arg t "$TEXT" '{text: $t}' \
  | curl -s -X POST "$BASE/v1/estimate_prosody" -H 'Content-Type: application/json' -d @- \
  | jq '.detail')"

# 人間用の一覧は stderr へ (stdout はリダイレクトして編集用に使うため)
jq -r 'to_entries[] | .key as $i | .value[] | "句\($i)\t\(.hira)\taccent=\(.accent)"' <<<"$DETAIL" >&2
jq -c . <<<"$DETAIL"
