#!/usr/bin/env bash

directory="$1"
type="${2:-hd}"

case "$type" in
  "uhd")
    find "$directory" -type d -mindepth 1 -maxdepth 1 -iname "*-1[3-9][0-9][0-9]x*" \( -iname "*h264*" -o -iname "*hevc*" \)
  ;;
  "not-uhd")
    find "$directory" -type d -mindepth 1 -maxdepth 1  \( -not -iname "*-1[3-9][0-9][0-9]x*" -o \( -not -iname "*h264*" -and -not -iname "*hevc*" \) \)
  ;;

  "hd")
    find "$directory" -type d -mindepth 1 -maxdepth 1 \( -iname "*1[0-2][0-9][0-9]x*" -o -iname "*x[7-9][0-9][0-9]-*" \) \( -iname "*h264*" -o -iname "*hevc*" \)
  ;;
  "not-hd")
    find "$directory" -type d -mindepth 1 -maxdepth 1 \( \( -not -iname "*1[0-2][0-9][0-9]x*" -and -not -iname "*x[7-9][0-9][0-9]-*" \) -o \( -not -iname "*h264*" -and -not -iname "*hevc*" \) \)
  ;;

  "hmd")
    find "$directory" -type d -mindepth 1 -maxdepth 1 -not -iname "*-[1-5][0-9][0-9]x[1-4][0-9][0-9]-*" -iname "*-[1-7][0-9][0-9]x[1-5][0-9][0-9]*" \( -iname "*h264*" -o -iname "*hevc*" \)
  ;;

  "not-hmd")
    find "$directory" -type d -mindepth 1 -maxdepth 1 \( -iname "*-[1-5][0-9][0-9]x[1-4][0-9][0-9]-*" -o -not -iname "*-[1-7][0-9][0-9]x[1-5][0-9][0-9]*" \) -o \( -not -iname "*h264*" -and -not -iname "*hevc*" \)
  ;;

  "mmd")
    find "$directory" -type d -mindepth 1 -maxdepth 1 -not -iname "*-[1-5][0-9][0-9]x[1-4][0-9][0-9]-*" -iname "*-[1-7][0-9][0-9]x[1-5][0-9][0-9]*" -iname "*\[mpeg4-*"
  ;;

  "not-mmd")
    find "$directory" -type d -mindepth 1 -maxdepth 1 \( -iname "*-[1-5][0-9][0-9]x[1-4][0-9][0-9]-*" -o -not -iname "*-[1-7][0-9][0-9]x[1-5][0-9][0-9]*" -o -not -iname "*\[mpeg4-*" \)
  ;;

  "ld")
    find "$directory" -type d -mindepth 1 -maxdepth 1 \( -iname "*-[1-5][0-9][0-9]x[1-4][0-9][0-9]-*" -o \( -not -iname "*\[mpeg4-*" -not -iname "*h264*" -not -iname "*hevc*" \) \)
  ;;

  "not-ld")
    find "$directory" -type d -mindepth 1 -maxdepth 1 \( -not -iname "*-[1-5][0-9][0-9]x[1-4][0-9][0-9]-*" \( -iname "*\[mpeg4-*" -o -iname "*h264*" -o -iname "*hevc*" \) \)
  ;;

  "not-fine")
    echo " > mpeg4 as follow"
    find "$directory" -type d -mindepth 1 -maxdepth 1 -not -iname "*h264*" -not -iname "*hevc*"
  ;;

  "ko")
    echo "NO accurate timing"
    find "$directory" -type d -mindepth 1 -maxdepth 1 -name "*KO*"
  ;;
esac


# ./filter-hd.sh "$base/x. the rest" hmd
# ./filter-hd.sh "$base/x. the rest" mmd


# Move shit around based on criteria
# while read -r line; do mv "$line" "/Volumes/OnePotato/Triage Grand Central/legacy/msmpeg/$(basename "$line")"; done < <(find /Volumes/OnePotato/Triage\ Grand\ Central/legacy/LD-batch-done -type d -iname "*msmpeg*")

# while read -r line; do mv "$line" "/Volumes/OnePotato/Triage Grand Central/legacy/move/$(basename "$line")"; done < <(find /Volumes/OnePotato/Triage\ Grand\ Central/legacy/LD-batch-done -type d -iname "*-3[0-9][0-9]x*")

# This is LD
# $h" -le 500 ] && [ "$w" -le 600

#while read -r line; do
#  mv "$line" "/Volumes/OnePotato/Triage Grand Central/legacy/move/$(basename "$line")"
#  basename "$line"
#done < <(
#  ./filter-hd.sh /Volumes/OnePotato/The\ End\ of\ Silence/3.\ mpeg4\ DVD/ not-mmd
#  find /Volumes/OnePotato/Triage\ Grand\ Central/legacy/LD-batch-done -type d -mindepth 1 -maxdepth 1 \( -iname "*-[1-5][0-9][0-9]x[1-4][0-9][0-9]-*" -o -not -iname "*\[mpeg4-*" \)

