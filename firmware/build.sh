#!/bin/sh
# build OWLOS Flight Radar with ESP-IDF 5.5 or 6.1 (the site is built with 5.5)
#   ./build.sh                      the 320x240 CYD
#   ./build.sh s2432s032            the 3.2" CYD, ESP32-2432S032
#   ./build.sh s2432s032 /dev/cu.usbserial-10   build, flash, monitor
# displays: ili9341 st7796 ili9486 gc9a01 es3c28p nmcydc5 crowadv28 crowadv50
#           jc8048w550 tab5 esp4827s043 crow70 crow50 s2432s032 epd400 epd792
# each display gets its own build folder and sdkconfig
set -eu
cd "$(dirname "$0")"
DISP=${1:-ili9341}
PORT=${2:-}
case "$DISP" in
  /dev/*|COM*|cu.*) PORT=$DISP; DISP=ili9341 ;;
esac
NUM=
TARGET=
case "$DISP" in
  ili9341) NUM=1; TARGET=esp32 ;;
  st7796) NUM=2; TARGET=esp32 ;;
  ili9486) NUM=3; TARGET=esp32 ;;
  gc9a01) NUM=4; TARGET=esp32c3 ;;
  epd400) NUM=5; TARGET=esp32s3 ;;
  epd792) NUM=6; TARGET=esp32s3 ;;
  es3c28p) NUM=7; TARGET=esp32s3 ;;
  nmcydc5) NUM=8; TARGET=esp32c5 ;;
  crowadv28) NUM=9; TARGET=esp32s3 ;;
  crowadv50) NUM=10; TARGET=esp32s3 ;;
  jc8048w550) NUM=11; TARGET=esp32s3 ;;
  tab5) NUM=12; TARGET=esp32p4 ;;
  esp4827s043) NUM=13; TARGET=esp32s3 ;;
  crow70) NUM=14; TARGET=esp32s3 ;;
  crow50) NUM=15; TARGET=esp32s3 ;;
  s2432s032) NUM=16; TARGET=esp32 ;;
  *) echo "unknown display $DISP" >&2; exit 1 ;;
esac
if [ "$NUM" = 1 ]; then
  BDIR=build
  SDK=$PWD/sdkconfig
else
  BDIR=build_$DISP
  SDK=$PWD/build_$DISP/sdkconfig
fi
# a normal Terminal has no idf.py. the Espressif install and the editor both record where 6.1 lives
idf_export() {
  [ -f "$1/tools/idf.py" ] || return 1
  here=$PWD
  cd "$1" || return 1
  set +eu
  # shellcheck disable=SC1091
  . ./export.sh
  ok=$?
  set -eu
  cd "$here" || return 1
  return "$ok"
}
if ! command -v idf.py >/dev/null 2>&1; then
  found=
  if [ -n "${IDF_PATH:-}" ] && [ -f "$IDF_PATH/export.sh" ]; then
    found=$IDF_PATH
  fi
  if [ -z "$found" ]; then
    for f in \
      "$HOME/Library/Application Support/Cursor/User/settings.json" \
      "$HOME/Library/Application Support/Code/User/settings.json" \
      "$HOME/Library/Application Support/Cursor/User/globalStorage/espressif.esp-idf-extension/esp_idf.json" \
      "$HOME/Library/Application Support/Code/User/globalStorage/espressif.esp-idf-extension/esp_idf.json" \
      "$HOME/.espressif/eim_idf.json"
    do
      [ -f "$f" ] || continue
      hit=$(sed -n 's/.*"idfPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p; s/.*"idf\.espIdfPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -1)
      if [ -n "$hit" ] && [ -f "$hit/export.sh" ]; then
        found=$hit
        break
      fi
    done
  fi
  if [ -z "$found" ]; then
    for d in \
      "$HOME/esp/v6.1.0/esp-idf" \
      "$HOME/esp/v6.1/esp-idf" \
      "$HOME/esp/esp-idf" \
      "$HOME/esp-idf" \
      "$HOME/.espressif/v6.1.0/esp-idf" \
      "$HOME/.espressif/frameworks/esp-idf-v6.1.0" \
      "$HOME/.espressif/frameworks/esp-idf-v6.1" \
      "$HOME"/esp/v6.1*/esp-idf \
      "$HOME"/.espressif/frameworks/esp-idf-v6.1* \
      "$HOME"/esp/*/esp-idf
    do
      if [ -f "$d/export.sh" ]; then
        found=$d
        break
      fi
    done
  fi
  if [ -z "$found" ]; then
    echo "ESP-IDF 6.1 was not found. In the folder that holds export.sh, run:" >&2
    echo "  export IDF_PATH=\"\$(pwd)\"" >&2
    echo "and start this script again." >&2
    exit 1
  fi
  echo "ESP-IDF $found"
  idf_export "$found"
fi
# a build folder made in another checkout keeps that path in its CMake cache
if [ -f "$BDIR/CMakeCache.txt" ] && ! grep -q "CMAKE_HOME_DIRECTORY:INTERNAL=$PWD" "$BDIR/CMakeCache.txt"; then
  echo "$BDIR was made in another folder, starting it fresh"
  rm -rf "$BDIR"
fi
PREVIEW=
if [ "$TARGET" = esp32c5 ]; then
  # 5.5.0 still calls the C5 a preview target. 6.1 does not, and ignores the flag
  PREVIEW=--preview
fi
set -- $PREVIEW -B "$BDIR" -DSDKCONFIG="$SDK" -DIDF_TARGET="$TARGET" -DRADAR_DISPLAY="$NUM"
if [ -z "$PORT" ]; then
  idf.py "$@" build
else
  idf.py "$@" -p "$PORT" build flash monitor
fi
