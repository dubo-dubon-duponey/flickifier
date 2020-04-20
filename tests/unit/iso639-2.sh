
. source/core/iso639-2.sh

_test(){
  local test="$1"
  local exit
  local ln
  local qual
  local rest
  local lnexp="$2"
  local qexp="$3"
  local rexp="$4"

  exit=0
  ln="$(language::extract::lang "$test")" || exit=$?

  dc-tools::assert::equal "0" "$exit"
  exit=0
  qual="$(language::extract::qualifier "$test")" || exit=$?
  dc-tools::assert::equal "0" "$exit"
  exit=0
  rest="$(language::extract::rest "$test")" || exit=$?
  dc-tools::assert::equal "0" "$exit"

  dc-tools::assert::equal "Ln of $test is $lnexp" "$lnexp" "$ln"
  dc-tools::assert::equal "Qual of $test is $qexp" "$qexp" "$qual"
  dc-tools::assert::equal "Rest of $test is $rexp" "$rexp" "$rest"
}

testIso639(){
  local test
  local exit
  local ln
  local qual
  local rest
  local lnexp
  local qexp
  local rexp

  _test "Nonesuch.srt" "" "" "Nonesuch.srt"

  _test "A Face in the Crowd.srt" "" "" "A Face in the Crowd.srt"

  _test "L'Innocente.en.srt" "en" "" "L'Innocente"
  _test "L'Innocente.pt.srt" "pt" "" "L'Innocente"

  _test "Eng.srt" "eng" "" ""
  _test "English.srt" "english" "" ""

  _test "Eng-forced.srt" "eng" "forced" ""
  _test "English-forced.srt" "english" "forced" ""

  _test "Eng-sdh.srt" "eng" "sdh" ""
  _test "English-sdh.srt" "english" "sdh" ""

  _test "foo.Eng-sdh.srt" "eng" "sdh" "foo"
  _test "foo.English-sdh.srt" "english" "sdh" "foo"

  _test "foo.Eng[(-sdh].srt" "eng" "sdh" "foo"
  _test "foo.English-sdh.srt" "english" "sdh" "foo"


  dc-tools::assert::equal "" "movie" "$(scene::remove "movie h264 webdl.mp4")"

}

testBrute(){
  while read -r line; do
    ln="$(language::extract::lang "$(basename "$line")")"
    if [ ! "$ln" ]; then
      echo ">>>> $(basename "$line")"
    fi
  done < <(find "/Volumes/OnePotato/The End Of Silence" -type f \( -iname "*.srt" -o -iname "*.sub" \))
}
