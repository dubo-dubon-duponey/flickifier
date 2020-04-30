_PRIVATE_PIRATEBAY_TRACKERS=

_PRIVATE_PBAY_CAT_ALL=0
_PRIVATE_PBAY_CAT_HD=207

index::piratebay::scrape(){
  local question="$1"
  local url

  url="$(printf "https://apibay.org/q.php?q=%s&cat=0" "$(dc::encoding::uriencode "$question")")"
#  dc-ext::http-cache::request "$url" "GET" | dc::wrapped::base64d | jq '[.[] | {hash: .info_hash, imdb: .imdb, id: .id, name: .name, seeders: .seeders, leechers: .leechers, size: .size, files: .num_files, category: .category}]'
  dc::http::request "$url" "GET" | jq '[.[] | {hash: .info_hash, imdb: .imdb, id: .id, name: .name, seeders: .seeders, leechers: .leechers, size: .size, files: .num_files, category: .category}]'
}

piratebay::trackers::get(){
  local tracker
  if [ ! "$_PRIVATE_PIRATEBAY_TRACKERS" ]; then
    while read -r tracker; do
      _PRIVATE_PIRATEBAY_TRACKERS="$_PRIVATE_PIRATEBAY_TRACKERS$(printf "&tr=%s" "$(dc::encoding::uriencode "$tracker")")"
    done < <(
      dc::http::request "https://thepiratebay.org/static/main.js" "GET" | grep "function print_trackers()" | perl -pe "s/encodeURIComponent/\nencodeURIComponent/g" | grep "encodeURIComponent" \
        | perl -pe "s/^encodeURIComponent\('([^']+).*/\1/"
    )
  fi
  printf "%s" "$_PRIVATE_PIRATEBAY_TRACKERS"
}

piratebay::scrape(){
  local url
  while read -r url; do
    url="$(perl -pe "s/.*\/torrent\/([0-9]+).*/https:\/\/apibay.org\/t.php?id=\1/" <<<"$url")"
    dc::logger::debug "piratebay::scrape $url"
#    dc-ext::http-cache::request "$url" "GET" | dc::wrapped::base64d | jq -rc '{hash: .info_hash, seeders: .seeders, name: .name, imdb: .imdb, size: .size, category: .category, files: .num_files}'
    dc::http::request "$url" "GET" | jq -rc '{hash: .info_hash, seeders: .seeders, name: .name, imdb: .imdb, size: .size, category: .category, files: .num_files}'
  done < /dev/stdin
}

