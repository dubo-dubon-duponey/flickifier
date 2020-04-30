_PRIVATE_MAGNETO_ROOT="$HOME/Downloads/teos/torrents"

dc::fs::isdir "$_PRIVATE_MAGNETO_ROOT" writable create

magneto::exist() {
  local hash="$1"
  [ -f "$_PRIVATE_MAGNETO_ROOT/$hash.torrent" ]
}

magneto::read() {
  local hash="$1"
  local result
  local size

  dc::logger::debug "magneto::read $hash"

  result="$(aria2c "$_PRIVATE_MAGNETO_ROOT/$hash.torrent" -S)"
  size="$(dc::wrapped::grep -i "Total length" <<<"$result" | perl -pe "s/.+[(]([0-9,]+)[)]/\1/" | tr -d ',')"

  printf '{"size": %s, "torrent": "%s",' "$size" "$_PRIVATE_MAGNETO_ROOT/$hash.torrent"

  printf '"files": ['
  local sep=""
  while read -r line; do
    dc::wrapped::grep -q "^[^|]*[0-9]+[|]" <<<"$line" || continue
    printf "%s" "$sep"
    sep=","
    perl -pe "s/[^|]*[|](.+)/\"\1\"/" <<<"$line"
  done <<<"$result"
  printf ']}'
}

magneto::tomagnet() {
  local hash="$1"
  local name="$2"
  local trackers="$3"
  local magnetlink
  printf "magnet:?xt=urn:btih:%s&dn=%s%s" "$hash" "$(dc::encoding::uriencode "$name")" "$trackers"
}

magneto::retrieve() {
  local hash="$1"
  local name="$2"
  local trackers="$3"
  local magnetlink
  magnetlink="$(printf "magnet:?xt=urn:btih:%s&dn=%s%s" "$hash" "$(dc::encoding::uriencode "$name")" "$trackers")"

  dc::logger::debug "magneto::retrieve $hash ($magnetlink)"
  [ -f "$_PRIVATE_MAGNETO_ROOT/$hash.torrent" ] || aria2c --bt-metadata-only=true --bt-save-metadata=true -d "$_PRIVATE_MAGNETO_ROOT" -q "$magnetlink"
}
