

readthis(){
  local this="$1"
  local depth="$2"
  >&2 echo "Processing $this (depth $depth)"
  while read -r line; do
    line="$(basename "$line")"
    perl -pe "s/^(.+tt[0-9]{7,}).+/\1/" <<<"$line"
#| perl -pe "s/\[//g" | perl -pe "s/\]//g"
  done < <(find "$this" -type d -mindepth "$depth" -maxdepth "$depth")
}

readthis /Volumes/OnePotato/The\ End\ of\ Silence/ "2"
readthis "$HOME"/Movies/The\ End\ of\ Silence "2"
# readthis "$HOME"/Movies/Rip "1"

readthis /Volumes/OnePotato/The\ Small\ End/pr0n/ "1"
readthis /Volumes/OnePotato/The\ Small\ End/Terrible\,\ Terrible\,\ but\ we\ are\ encyclopedists/ "1"


# ./dupe.sh > list.txt; cat list.txt | sort | uniq -d
