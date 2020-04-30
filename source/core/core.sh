#!/usr/bin/env bash

dc-ext::http-cache::request(){
  local url="$1"
  local method
  method="$(printf "%s" "$2" | tr '[:lower:]' '[:upper:]')"
  shift
  shift

  local body

  # If not GET or HEAD, ignore caching entirely
  if [ "$method" != "GET" ] && [ "$method" != "HEAD" ]; then
    DC_HTTP_CACHE=miss
    _dc_internal_ext::simplerequest "$url" "$method" "$@" | base64
    return
  fi

  # Otherwise, look-up the cache first
  body=$(dc-ext::sqlite::select "dchttp" "content" "method='$method' AND url=\"$url\"")
  DC_HTTP_STATUS=200
  DC_HTTP_CACHE=hit

  local ex=0
  # Nothing? Or forced to refresh?
  if [ ! "$body" ] || [ "$DC_HTTP_CACHE_FORCE_REFRESH" ]; then
    export DC_HTTP_CACHE=miss
#    >&2 echo ">>> will query now"
    if body="$(_dc_internal_ext::simplerequest "$url" "$method" "" /dev/stdout "$@" | base64)"; then
      # Ensure there is nothing in here
      dc-ext::sqlite::delete "dchttp" "url=\"$url\" AND method='$method'" || true
      # Insert in the database
#      >&2 echo ">>> will insert in db"
      dc-ext::sqlite::insert "dchttp" "url, method, content" "\"$url\", '$method', '$body'"
    else
      ex="$ERROR_NETWORK"
    fi
  fi
  printf "%s" "$body"
  return "$ex"
}

_dc_internal_ext::simplerequest(){
  dc::http::request "$@" || return
#  >&2 echo ">>> status: $DC_HTTP_STATUS (err bet; $ERROR_NETWORK)"
  [ "$DC_HTTP_STATUS" == 200 ] || return "$ERROR_NETWORK"
}

dc::encoding::uriencode() {
  local s
  s="${*//'%'/%25}"
  s="${s//' '/%20}"
  s="${s//'"'/%22}"
  s="${s//'#'/%23}"
  s="${s//'$'/%24}"
  s="${s//'&'/%26}"
  s="${s//'+'/%2B}"
  s="${s//','/%2C}"
  s="${s////%2F}"
  s="${s//':'/%3A}"
  s="${s//';'/%3B}"
  s="${s//'='/%3D}"
  s="${s//'?'/%3F}"
  s="${s//'@'/%40}"
  s="${s//'['/%5B}"
  s="${s//']'/%5D}"
  printf %s "$s"
}
