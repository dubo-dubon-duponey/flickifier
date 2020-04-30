#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="0.1.0"
# shellcheck disable=SC2034
readonly CLI_DESC="imdb json client, with caching"

# Init
dc::commander::initialize
# Flags
#dc::commander::declare::flag limit "$DC_TYPE_INTEGER" "limit the number of results to be retrieved and analyzed (default to 50 if left empty" optional
dc::commander::declare::flag min-peers "$DC_TYPE_INTEGER" "Minimum number of peers to try and retrieve torrent information (default to 5)" optional
# dc::commander::declare::arg 1 "^(search|retrieve)$" "command" "Search term - can be an imdb (eg: tt0000001), or any name"
dc::commander::declare::arg 1 ".+" "search" "Search term - can be an imdb (eg: tt0000001), or any name"
# Start commander
dc::commander::boot
# Requirements
dc::require jq 1.5
dc::require aria2c

dc::fs::isdir "$HOME/tmp/fi-sucker/torrent-cache" writable create

dc-ext::sqlite::init "$HOME/tmp/fi-sucker/cache.db"
dc-ext::http-cache::init

piratebay::trackers::get > /dev/null

site="https://thepiratebay.org"
# question="tt0012349"
question="$DC_ARG_1"
limit=""
! dc::args::exist limit || limit="$DC_ARG_LIMIT"
min_peers=""
! dc::args::exist min-peers || min_peers="$DC_ARG_MIN_PEERS"



cat_hires_video=207
cat_video=201
cat_show=205
cat_music=101

#  dc-ext::http-cache::request "https://www.google.com/search?q=site%3A$(dc::encoding::uriencode "${site}")+$(dc::encoding::uriencode "${question}")" "GET" "" "" "User-Agent: Firefox" \
#    | dc::wrapped::base64d \
#    | perl -pe 's/(<a[^>]+>)/\n\1\n/g' \
#    | grep "$site"



# _dc_internal_ext::simplerequest http://google.fr

dc::logger::warning "Auditing $question"
data="$(index::piratebay::scrape "$question")"
length="$(jq "length" <<<"$data")"
for (( x=0; x<length; x++)); do
  line="$(jq .[$x] <<<"$data")"
  id="$(jq -rc .id <<<"$line")"
  [ "$id" != 0 ] || {
    dc::logger::error " > No result returned for $question"
    exit
  }
  name="$(jq -rc .name <<<"$line")"
  hash="$(jq -rc .hash <<<"$line")"
  seeders="$(jq -rc .seeders <<<"$line")"
  leechers="$(jq -rc .leechers <<<"$line")"
  category="$(jq -rc .category <<<"$line")"
  dc::logger::warning " > Candidate torrent $name"
  if [ "${category:0:1}" != 2 ]; then
    dc::logger::warning "   | Not a video. What is this?"
#    continue
  fi


#  if ! magneto::exist "$hash"; then

#    if [ "$((leechers + seeders))" -lt "${min_peers:-3}" ]; then
#      dc::logger::error " | Peer number below threshold ($((seeders + leechers))). Ignoring for now. Lower threshold if you want to keep it in."
#      continue
#    fi

#    dc::prompt::question "Interested in this? [y/N]" interest
#    if [ "$interest" != "y" ]; then
#      dc::logger::warning " | Ignoring at your request. "
#      continue
#    fi
#  fi

#  jq -rc <<<"$line"

  jq --arg magneto "$(magneto::tomagnet "$hash" "$name" "$(piratebay::trackers::get)")" -rc '. + {magnet: $magneto}' <<<"$line"

done

exit



# | {
  while read -r line; do
    hash="$(jq -rc .hash <<<"$line")"

    seeders="$(jq -rc .seeders <<<"$line")"
    leechers="$(jq -rc .seeders <<<"$line")"
    name="$(jq -rc .name <<<"$line")"
    if ! magneto::exist "$hash"; then
      if [ "$((leechers + seeders))" -lt "${min_peers:-3}" ]; then
        dc::logger::error " | Peer number below threshold ($seeders / $leechers). Trying this is ill advised."
        continue
      fi
      magneto::retrieve "$hash" "$name" "$(piratebay::trackers::get)"
    fi

    torrent="$(magneto::read "$hash" | jq -rc .torrent)"
    files="$(magneto::read "$hash" | jq -rc .files)"

    printf "%s" "$line" | jq --argjson files "$files" --arg torrent "$torrent" -r '{
      hash: .hash,
      seeders: .seeders,
      leechers: .leechers,
      name: .name,
      imdb: .imdb,
      size: .size,
      category: .category,
      files: $files,
      torrent: $torrent
    }'

  done < /dev/stdin
# }



exit


echo | {

  while read -r line; do
    hash="$(jq -rc .hash <<<"$line")"
    seeders="$(jq -rc .seeders <<<"$line")"
    leechers="$(jq -rc .seeders <<<"$line")"
    name="$(jq -rc .name <<<"$line")"
    if ! magneto::exist "$hash"; then
      if [ "$((leechers + seeders))" -lt "${min_seeders:-3}" ]; then
        dc::logger::error " | Peer number below threshold ($seeders / $leechers). Trying this is ill advised."
        continue
      fi
      magneto::retrieve "$hash" "$name" "$(piratebay::trackers::get)"
    fi

    torrent="$(magneto::read "$hash" | jq -rc .torrent)"
    files="$(magneto::read "$hash" | jq -rc .files)"

    printf "%s" "$line" | jq --argjson files "$files" --arg torrent "$torrent" -r '{
      hash: .hash,
      seeders: .seeders,
      leechers: .leechers,
      name: .name,
      imdb: .imdb,
      size: .size,
      category: .category,
      files: $files,
      torrent: $torrent
    }'

    sleep 60

  done < /dev/stdin

}


exit


# Google tends to blacklist too easily
while read -r line; do
  name="$(jq -rc .name <<<"$line")"
  seeders="$(jq -rc .seeders <<<"$line")"
  hash="$(jq -rc .hash <<<"$line")"
  imdb="$(jq -rc .imdb <<<"$line")"
  size="$(jq -rc .size <<<"$line")"
  category="$(jq -rc .category <<<"$line")"
  files="$(jq -rc .files <<<"$line")"

  dc::logger::warning "Analyzing torrent $name"

  if [ "${category:0:1}" != 2 ]; then
    dc::logger::error " > Not a video"
    continue
  fi

  if ! magneto::exist "$hash"; then
    if [ "$seeders" -lt "${min_seeders:-3}" ]; then
      dc::logger::error " > Not enough seeders for this torrent ($seeders). Ignoring"
      continue
    fi
    dc::logger::error "Seeders: $seeders"
    magneto::retrieve "$hash" "$name" "$(piratebay::trackers::get)"
  fi

  torrent="$(magneto::read "$hash" | jq -rc .torrent)"
  files="$(magneto::read "$hash" | jq -rc .files)"
  printf "%s" "$line" | jq --argjson files "$files" --arg torrent "$torrent" -r '{
    hash: .hash,
    seeders: .seeders,
    name: .name,
    imdb: .imdb,
    size: .size,
    category: .category,
    files: $files,
    torrent: $torrent
  }'

#  dc::output::json "$line"

#  dc::output::json "$line"
done < <(index::google::scrape "$site" "$question" "/torrent/" "$limit" | piratebay::scrape)


# magnet:?xt=urn:btih:0697BC07EBC5914085C2A3BCE646509086BF6265&dn=Charlie%20Chaplin%20-%20The%20Kids%20(1921)%20720p%20BrRipx%20-%20300MB%20-%20YIFY&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2920%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=udp%3A%2F%2Ftracker.internetwarriors.net%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.pirateparty.gr%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.cyberia.is%3A6969%2Fannounce
# magnet:?xt=urn:btih:0697BC07EBC5914085C2A3BCE646509086BF6265&dn=Charlie%20Chaplin%20-%20The%20Kids%20(1921)%20720p%20BrRipx%20-%20300MB%20-%20YIFY&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2920%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=udp%3A%2F%2Ftracker.internetwarriors.net%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.pirateparty.gr%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.cyberia.is%3A6969%2Fannounce
# Processed:
# magnet:?xt=urn:btih:36CC1359D05AE57D6B461932356A205DDEF9E681&dn=The.Kid.1921.x264.DTS-WAF&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2F9.rarbg.to%3A2920%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=udp%3A%2F%2Ftracker.internetwarriors.net%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.leechers-paradise.org%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.pirateparty.gr%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.cyberia.is%3A6969%2Fannounce
