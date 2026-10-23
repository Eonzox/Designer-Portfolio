#!/bin/bash
# Img 폴더의 이미지를 웹용 크기로 줄여 assets.js 하나로 묶어요.
# 이미지를 바꾸거나 추가한 뒤 이 파일을 더블클릭하면 돼요.
# (assets.js가 있어야 index.html을 더블클릭해서 열어도 3D 효과가 나와요)

set -e
cd "$(dirname "$0")"

TMP="$(mktemp -d)"
OUT="assets.js"
trap 'rm -rf "$TMP"' EXIT

echo "window.PORTFOLIO_IMAGES = {" > "$OUT.tmp"

find Img -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | sort | while IFS= read -r src; do
  width=$(sips -g pixelWidth "$src" | awk '/pixelWidth/{print $2}')
  height=$(sips -g pixelHeight "$src" | awk '/pixelHeight/{print $2}')
  work="$TMP/work.png"
  cp "$src" "$work"

  case "$src" in
    Img/Walla/*)
      target=1200 ;;   # 1440×900 웹 화면
    *)
      target=360       # 375×812 모바일 화면
      # 폰 테두리가 포함된 이미지(가로 1500 초과)는 화면 부분만 남겨요
      if [ "$width" -gt 1500 ] && [ "$width" -lt 1700 ]; then
        inset=$(( (width - 1500) / 2 ))
        sips -c $(( height - inset * 2 )) 1500 "$work" > /dev/null
      fi ;;
  esac

  sips --resampleWidth "$target" -s format jpeg -s formatOptions 85 "$work" --out "$TMP/out.jpg" > /dev/null
  printf '  "%s": "data:image/jpeg;base64,%s",\n' "$src" "$(base64 -i "$TMP/out.jpg" | tr -d '\n')" >> "$OUT.tmp"
  echo "  ✓ $src"
done

echo "};" >> "$OUT.tmp"
mv "$OUT.tmp" "$OUT"
echo ""
echo "완료: $OUT ($(du -h "$OUT" | cut -f1))"
