index::google::scrape::one() {
  local target="$1"
  local question="$2"
  local match="${3:-}"
  local start="${4:-0}"

  dc::logger::debug "scrapper::google https://www.google.com/search?start=$start&q=site%3A$(dc::encoding::uriencode "${target}")+$(dc::encoding::uriencode "\"${question}\"")"
  # XXX quick and dirty - elimitation is a bit broad
  # dc::http::request "https://www.google.com/search?start=$start&q=site%3A$(dc::encoding::uriencode "${target}")+$(dc::encoding::uriencode "${question}")" "GET" "" "" "User-Agent: Chrome" \

  dc-ext::http-cache::request "https://www.google.com/search?start=$start&q=site%3A$(dc::encoding::uriencode "${target}")+$(dc::encoding::uriencode "\"${question}\"")" "GET" "" "" "User-Agent: Firefox" |
    dc::wrapped::base64d |
    perl -pe 's/(<a[^>]+>)/\n\1\n/g' |
    dc::wrapped::grep "^<a " |
    dc::wrapped::grep -v "href=\"[^\"]+[.]google[.]" |
    dc::wrapped::grep -v "href=\"[^\"]+[.]youtube[.]" |
    dc::wrapped::grep -v "href=\"[^\"]+[.]chillingeffects[.]org" |
    dc::wrapped::grep -v "href=\"/" |
    dc::wrapped::grep -v "href=\"#" |
    dc::wrapped::grep "$match" |
    perl -pe "s/.*href=\"([^\"]+)\".*/\1/" || {
      local exit=$?

      if dc-ext::http-cache::request "https://www.google.com/search?start=$start&q=site%3A$(dc::encoding::uriencode "${target}")+$(dc::encoding::uriencode "\"${question}\"")" "GET" "" "" "User-Agent: Firefox" "Accept-language: en-US,en;q=0.7" \
        | dc::wrapped::base64d \
        | dc::wrapped::grep "did not match any documents"; then
        dc::logger::error "No match!"
        return "$exit"
      fi

      dc::logger::error "Dramatic error! See below"
      dc::logger::error "$(dc-ext::http-cache::request "https://www.google.com/search?start=$start&q=site%3A$(dc::encoding::uriencode "${target}")+$(dc::encoding::uriencode "\"${question}\"")" "GET" "" "" "User-Agent: Firefox" "Accept-language: en-US,en;q=0.7" \
        | dc::wrapped::base64d \
      )"
      dc::logger::error "Dramatic error! See above"
  }
}

# XXX for some reason, it appears we fork at some time????
index::google::scrape() {
  local target="$1"
  local question="$2"
  local match="${3:-}"
  local limit="${4:-100}"

  local start=0
  local result=""
  local count=0

  while [ "$count" -lt "$limit" ]; do
    #    >&2 echo "Count is $count limit is $limit start is $start"
    if ! result="$(index::google::scrape::one "$target" "$question" "$match" "$start")" || [ ! "$result" ]; then
      dc::logger::error "Google search stopped prematurely. Out of results is likely."
      break
    fi
    printf "%s\n" "$result"
    inc=$(wc -l <<<"$result")
    count=$((count + inc))
    start=$((start + 10))
    sleep 3
  done
}
