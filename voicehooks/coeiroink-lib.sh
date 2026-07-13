#!/usr/bin/env bash
# COEIROINK 共通処理 (generate-voices.sh / tune-voice.sh から source される)。
# WSL2: COEIROINK は Windows 側で動くため、localhost で届かなければ
# デフォルトゲートウェイ (Windows ホスト) を試す。
# 接続先の上書き: COEIROINK_URL=http://<host>:50032

coeiroink_resolve_base() {
  if [ -n "${COEIROINK_URL:-}" ]; then
    echo "$COEIROINK_URL"
    return
  fi
  if curl -s --max-time 2 "http://localhost:50032/v1/speakers" >/dev/null 2>&1; then
    echo "http://localhost:50032"
    return
  fi
  local gw
  gw="$(ip route show default | awk '{print $3; exit}')"
  if [ -n "$gw" ] && curl -s --max-time 2 "http://$gw:50032/v1/speakers" >/dev/null 2>&1; then
    echo "http://$gw:50032"
    return
  fi
  echo "error: COEIROINK に接続できません (localhost / $gw を試行)" >&2
  echo "  - Windows 側で COEIROINK が起動しているか確認" >&2
  echo "  - .wslconfig で networkingMode=mirrored にするか、COEIROINK_URL で明示指定" >&2
  return 1
}

# $1=BASE $2=リクエストJSON $3=出力wavパス。wav 以外の応答なら先頭を表示して失敗。
coeiroink_synth() {
  curl -s -X POST "$1/v1/synthesis" -H 'Content-Type: application/json' \
    -d "$2" -o "$3" </dev/null
  if ! head -c 4 "$3" | grep -q 'RIFF'; then
    echo "NG (wav ではない応答):" >&2
    head -c 200 "$3" >&2
    echo >&2
    return 1
  fi
}
