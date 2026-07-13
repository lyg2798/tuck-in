#!/bin/bash
#
# Tuck-in 터미널 설치 스크립트.
#   curl -fsSL https://lyg2798.github.io/tuck-in/install.sh | bash
#
# 최신 릴리스 dmg(공증됨)를 받아 /Applications 에 설치하고 실행한다.
# 소스: https://github.com/lyg2798/tuck-in  (이 스크립트가 하는 일이 궁금하면 먼저 내려받아 읽어보세요:
#   curl -fsSL https://lyg2798.github.io/tuck-in/install.sh -o tuck-in-install.sh && less tuck-in-install.sh)
set -euo pipefail

APP="Tuck-in"
URL="https://github.com/lyg2798/tuck-in/releases/latest/download/${APP}.dmg"

# macOS 전용.
if [[ "$(uname)" != "Darwin" ]]; then
  echo "Tuck-in 은 macOS 전용입니다." >&2
  exit 1
fi

TMP="$(mktemp -d)"
DMG="${TMP}/${APP}.dmg"
MNT=""
cleanup() {
  [[ -n "$MNT" ]] && hdiutil detach "$MNT" -quiet 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

echo "↓  최신 ${APP} 다운로드 중…"
curl -fL# "$URL" -o "$DMG"

echo "·  디스크 이미지 마운트…"
MNT="$(hdiutil attach "$DMG" -nobrowse -noautoopen | grep -oE '/Volumes/[^	]+' | tail -1)"
if [[ -z "$MNT" || ! -d "${MNT}/${APP}.app" ]]; then
  echo "error: dmg 안에서 ${APP}.app 을 찾지 못했습니다." >&2
  exit 1
fi

# 설치 위치: /Applications (쓰기 권한 없으면 sudo). 관리자 계정은 보통 암호 없이 됩니다.
DEST="/Applications"
SUDO=""
if [[ ! -w "$DEST" ]]; then
  echo "·  /Applications 설치에 관리자 암호가 필요할 수 있어요."
  SUDO="sudo"
fi

echo "·  ${DEST}/${APP}.app 로 설치…"
$SUDO rm -rf "${DEST}/${APP}.app"
$SUDO cp -R "${MNT}/${APP}.app" "${DEST}/"

# 공증돼 있어 보통 불필요하지만, 첫 실행을 매끄럽게(격리 속성 제거).
$SUDO xattr -dr com.apple.quarantine "${DEST}/${APP}.app" 2>/dev/null || true

echo "✓  설치 완료 — ${APP} 를 실행합니다."
open "${DEST}/${APP}.app"
