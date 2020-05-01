#!/usr/bin/env bash
director="$1"
movies="$(./bin/flck-meta "$(./bin/flck-meta --type=person "$director" | jq -rc .[0].id)" | jq -rc '.movies.director[].id' | sort)"

readthis(){
  local this="$1"
  local depth="$2"
  >&2 echo "Processing $this (depth $depth)"
  while read -r line; do
    line="$(basename "$line")"
    perl -pe "s/^.+(tt[0-9]{7,}).+/\1/" <<<"$line"
#| perl -pe "s/\[//g" | perl -pe "s/\]//g"
  done < <(find "$this" -type d -mindepth "$depth" -maxdepth "$depth")
}

echo "----------------------"
collection="$(readthis /Volumes/OnePotato/The\ End\ of\ Silence/ "2" | sort)"

diff --new-line-format="" --unchanged-line-format=""  <(echo "$movies") <(echo "$collection")
