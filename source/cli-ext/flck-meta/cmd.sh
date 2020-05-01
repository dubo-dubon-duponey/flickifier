#!/usr/bin/env bash

# XXX
# Runtime broken with tt0000240

true
# shellcheck disable=SC2034
readonly CLI_VERSION="0.1.0"
# shellcheck disable=SC2034
readonly CLI_DESC="cinema metadata information search and retrieval"

# Init
dc::commander::initialize
# Flags
dc::commander::declare::flag refresh "^$" "ignores local cache if set" optional
dc::commander::declare::flag type "^(title|person)$" "if searching, point towards titles or persons - ignored otherwise" optional
dc::commander::declare::flag year "^[0-9]{4}$" "when searching for a movie, restrict search to that year" optional
dc::commander::declare::flag role "^.+$" "if looking up a person results by id, returns only the movies matching that role for that person, defaulting to director (ignored otherwise)" optional

dc::commander::declare::arg 1 "^.+$" "term" "argument to be searched or retrieved (either a plain text search, or an imdb identifier, like tt0000001)"
#dc::commander::declare::arg 1 "^(search|info|picture)$" "command" "command to execute - either search, info, or picture"
# dc::commander::declare::flag image "^(show|dump)$" "retrieve the cover image and print it to stdout ('dump') or display it (iterm2 only, 'show')" optional

# flck-meta --type=person "David Lynch"
# flck-meta --type=title "Lost Highway"
# flck-meta "Lost Highway"
# flck-meta --year="1997" "Lost Highway"

# flck-meta get "tt0000001"
# flck-meta get "nm0000001"
# flck-meta "tt9000002"
# flck-meta "tt9900002"

# Start commander
dc::commander::boot
# Requirements
dc::require jq 1.5

# Init sqlite
dc::fs::isdir "$HOME/tmp/flck-meta" writable create
dc-ext::sqlite::init "$HOME/tmp/flck-meta/cache.db"
dc-ext::http-cache::init

# Configure the client
! dc::args::exist refresh || flck::cachebust true
flck::ua "flck-meta/1.0"


op="search"
type="${DC_ARG_TYPE:-title}"
if dc::argument::check DC_ARG_1 "^tt[0-9]{7,}"; then
  op="get"
  type="title"
elif dc::argument::check DC_ARG_1 "^nm[0-9]{7,}"; then
  op="get"
  type="person"
fi

case "$op" in
  "search")
    type=title
    ! dc::args::exist type || type="$DC_ARG_TYPE"
    if [ "$type" == "person" ]; then
      result="$(flck::requestor::imdb::search::name "$DC_ARG_1")"
    else
      result="$(flck::requestor::imdb::search::title "$DC_ARG_1" "${DC_ARG_YEAR:-}")"
    fi
  ;;
  "get")
    if [ "$type" == "person" ]; then
      result="$(flck::requestor::imdb::get::name "$DC_ARG_1" "${DC_ARG_ROLE:-}")"
    else
      result="$(flck::requestor::imdb::get::title "$DC_ARG_1")"
    fi
  ;;
esac

dc::output::json "$result"

# flck::requestor::imdb::get::title "$DC_ARG_1"

# Year open range
#   {
#    "id": "tt2390678",
#    "title": "American Greed, the Fugitives",
#    "picture": "https://m.media-amazon.com/images/M/MV5BMjA3Mzg2OTU0Ml5BMl5BanBnXkFtZTgwMTI5NDAxMzE@._V1_UY98_CR32,0,67,98_AL_.jpg",
#    "year": "2012– ",
#    "director": "Robert Greenwald",
#    "runtime": "103"
#  },

# Year range
#   {
#    "id": "tt1066700",
#    "title": "Heart and Greed",
#    "picture": "https://m.media-amazon.com/images/M/MV5BNzM4NDcwNjktMmYxMi00NGEwLWJlNGYtNzliYzlmMmUwN2MzXkEyXkFqcGdeQXVyMjQ0OTYxOTc@._V1_UY98_CR1,0,67,98_AL_.jpg",
#    "year": "2017–2018",
#    "director": "Zachary Wanerman",
#    "runtime": "43"
#  },

# Year qualifier
#   {
#    "id": "tt0394835",
#    "title": "Treachery and Greed on the Planet of the Apes",
#    "picture": "https://m.media-amazon.com/images/M/MV5BNjI2MjJmYTgtNGFjZS00MjJlLTlkNDYtYzg5NjM5YjIyMjlhXkEyXkFqcGdeQXVyMTYxNjkxOQ@@._V1_UY98_CR2,0,67,98_AL_.jpg",
#    "year": "1980 TV Movie",
#    "director": "Zachary Wanerman",
#    "runtime": "90"
#  },


showpicture(){
  local pic="$1"
  local show="$2"
  local body

  body="$(dc-ext::http-cache::request "$pic" GET)"

  if [ "$show" ]; then
    if [ "$TERM_PROGRAM" != "iTerm.app" ]; then
      dc::logger::error "You need iTerm2 to display the image"
      exit "$ERROR_GENERIC_FAILURE"
    fi
    printf "\\033]1337;File=name=%s;inline=1;preserveAspectRatio=true;width=50:%s\\a" "$pic" "$body"
    return
  fi

  printf "%s" "$body" | dc::wrapped::base64d
}

