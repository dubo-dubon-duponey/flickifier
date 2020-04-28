#!/usr/bin/env bash

# XXX
# Runtime broken with tt0000240

true
# shellcheck disable=SC2034
readonly CLI_VERSION="0.1.0"
# shellcheck disable=SC2034
readonly CLI_DESC="imdb json client, with caching"

# Init
dc::commander::initialize
# Flags
dc::commander::declare::flag image "^(show|dump)$" "retrieve the cover image and print it to stdout ('dump') or display it (iterm2 only, 'show')" optional
dc::commander::declare::arg 1 "^tt[0-9]{7}$" "imdbID" "the id of the movie (eg: tt0000001)"
# Start commander
dc::commander::boot
# Requirements
dc::require jq 1.5

# Init sqlite
dc-ext::sqlite::init "$HOME/tmp/fi-client-imdb/cache.db"
dc-ext::http-cache::init

# Request the main page and get the body

body="$(dc-ext::http-cache::request "https://www.imdb.com/title/$DC_ARG_1/" GET | dc::wrapped::base64d | tr '\n' ' ')"

# Extract the shema.org section, then the original title and picture url
schema=$(printf "%s" "$body" | sed -E 's/.*<script type="application\/ld[+]json">([^<]+).*/\1/')

# >&2 jq <<<"$schema"

IMDB_SCHEMA_TITLE=$(printf "%s" "$schema" | jq -r '.name')
IMDB_SCHEMA_PICTURE=$(printf "%s" "$schema" | jq -r 'select(.image != null).image')
IMDB_SCHEMA_TYPE=$(printf "%s" "$schema" | jq -r '."@type"')
IMDB_SCHEMA_DATE=$(printf "%s" "$schema" | jq -r 'select(.datePublished != null).datePublished')
# dc::output::json "$schema"
IMDB_SCHEMA_DIRECTOR=$(printf "%s" "$schema" | jq -r 'select(.director != null).director | if type=="array" then .[0].name else .name end')
IMDB_SCHEMA_CREATOR=$(printf "%s" "$schema" | jq -r 'select(.creator != null).creator | if type=="array" then .[0] else . end | select(.name != null).name')
IMDB_SCHEMA_DURATION=$(printf "%s" "$schema" | jq -r 'select(.duration != null).duration')

# If we are being asked about the image, go for it, using fancy iterm extensions if they are here
if dc::args::exist image; then
  if [ ! "$IMDB_SCHEMA_PICTURE" ]; then
    dc::logger::error "This movie does not come with a picture."
    exit "$ERROR_GENERIC_FAILURE"
  fi
  body="$(dc-ext::http-cache::request "$IMDB_SCHEMA_PICTURE" GET)"

  if [ "$DC_ARG_IMAGE" == "show" ]; then
    if [ "$TERM_PROGRAM" != "iTerm.app" ]; then
      dc::logger::error "You need iTerm2 to display the image"
      exit "$ERROR_GENERIC_FAILURE"
    fi
    printf "\\033]1337;File=name=%s;inline=1;preserveAspectRatio=true;width=50:%s\\a" "$DC_ARG_1" "$body"
    exit
  fi
  printf "%s" "$body" | dc::wrapped::base64d
  exit
fi

# Otherwise, move on

# Process the body to get the title, year and type
cleaned=$(printf "%s" "${body}" | sed -E "s/.*<meta property='og:title' ([^>]+).*/\1/" | sed -E 's/.*content=\"([^\"]+)\".*/\1/')
IMDB_YEAR=$(printf "%s" "$cleaned" | sed -E "s/^.*[(]([^)]*[0-9]{4}[–0-9]*)[)].*/\\1/")
IMDB_YEAR=${IMDB_YEAR##* }
IMDB_TITLE=$(printf "%s" "$cleaned" | sed -E "s/(.*)[[:space:]]+[(][^)]*[0-9]{4}[–0-9]*[)].*/\1/" | sed -E 's/&quot;/"/g')

cleaned=$(printf "%s" "${body}" | sed -E "s/.*<meta property='og:type' ([^>]+).*/\1/" | sed -E 's/.*content=\"([^\"]+)\".*/\1/')
IMDB_TYPE=$(printf "%s" "$cleaned")

# Now, fetch the technical specs
body="$(dc-ext::http-cache::request "https://www.imdb.com/title/$DC_ARG_1/technical" GET)" || exit

extractTechSpecs(){
  local body="$1"
  local sep
  local techline
  local key
  local value
  local ar=""

  local technical

  technical=$(printf "%s" "$body" | sed -E 's/.*<tbody>(.*)<\/tbody>.*/\1/')

  while
      techline=${technical%%"</tr>"*}
      [ "$techline" != "$technical" ]
  do
    sep='<td class="label">'
    techline=${techline#*"$sep"}
    technical=${technical#*"</tr>"}
    key=${techline%%"</td>"*}
    value=${techline#*"<td>"}
    value=${value%%"</td>"*}
    # XXX need to escape double quotes
    value="$(perl -pe "s/[\"]/\\\\\"/g" <<<"$value")"
    # XXX sed will introduce a trailing line feed
    key="$(printf "%s" "$key" | sed -E 's/[[:space:]]*$//' | sed -E 's/^[[:space:]]*//' | tr -d '\n' | tr '[:lower:]' '[:upper:]' | tr '[:space:]' '_')"

    printf '%s"%s": [' "$ar" "$key"
    ar=", "

    ec=""
    # >&2 printf ">>>>%s<<<" "$value"
    if [ "$key" == "SOUND_MIX" ] || [ "$key" == "COLOR" ]; then
      sep='<span class="ghost">|</span>'
      while IFS= read -r -d '' i; do
        i="$(printf "%s" "$i" | sed -E 's/<[^>]+>//g' | sed -E 's/[[:space:]]*$//' | sed -E 's/^[[:space:]]*//' | sed -E 's/[[:space:]]{2,}/ /g')"
        printf '%s"%s"' "$ec" "$i"
        ec=", "
      done < <( dc::string::split value sep )
    elif [ "$key" == "RUNTIME" ]; then
      sep="<br>"
      while IFS= read -r -d '' i; do
      # tt0000110 <- 25 sec
      # tt0000439 <- 11 min and FPS indication
      # tt0074749 <- multiple times with indication
#        i="$(sed -E 's/.*[ (]([0-9]+ [a-z]{3})[[:space:])]*(.*)?$/\1 \2/' <<<"$i" | sed -E 's/[[:space:]]*$//')"
        # >&2 echo "Trying to process $i"
        local hr=0
        local min=0
        local sec=0
        local rest=""
        ! dc::wrapped::grep -q "([0-9]+) hr" <<<"$i" || hr="$(sed -E 's/.*([0-9]+) hr.*/\1/' <<<"$i")"
        ! dc::wrapped::grep -q "([0-9]+) min[^)]" <<<"$i" || min="$(sed -E 's/(.*[[:space:]*])?([0-9]+) min.*/\2/' <<<"$i")"
        ! dc::wrapped::grep -q "([0-9]+) sec" <<<"$i" || sec="$(sed -E 's/(.*[[:space:]*])?([0-9]+) sec.*/\2/' <<<"$i")"

        rest="$(sed -E 's/[^(]+([(][0-9]+ min[)] )?(.*)/\2/' <<<"$i" | sed -E 's/[[:space:]]*$//')"

        # >&2 echo "Hour: $hr - Min: $min - Sec: $sec - Rest: $rest"

        i="$((hr * 60 + min))"
        if [ "$sec" != 0 ]; then
          i="$((i + 1))"
        fi
        if [ "$rest" ]; then
          i="$i $rest"
        fi
        printf '%s"%s"' "$ec" "$i" # | sed -E 's/.*[ (]([0-9]+ min)[[:space:])]*(.*)?$/\1 \2/' | sed -E 's/[[:space:]]*$//' | dc::string::trimSpace
        ec=", "
      done < <( dc::string::split value sep )
    else
      sep="<br>"
      while IFS= read -r -d '' i; do
        i="$(printf "%s" "$i" | sed -E 's/<[^>]+>//g' | sed -E 's/[[:space:]]*$//' | sed -E 's/^[[:space:]]*//' | sed -E 's/[[:space:]]{2,}/ /g')"
        printf '%s"%s"' "$ec" "$i"
        ec=", "
      done < <( dc::string::split value sep )
    fi
    printf "]"
  done
}

# Extract the specs
heads="$(extractTechSpecs "$(printf "%s" "$body" | dc::wrapped::base64d | tr -d '\n')")"

#    echo ">$heads<"

dc::logger::debug "$heads"
#echo ">$IMDB_YEAR<"
#echo ">$IMDB_TITLE<"
#echo ">$IMDB_TYPE<"

output=$(printf "%s" "{$heads}" | jq \
  --arg title     "$IMDB_TITLE" \
  --arg year      "$IMDB_YEAR" \
  --arg date      "$IMDB_SCHEMA_DATE" \
  --arg original  "$IMDB_SCHEMA_TITLE" \
  --arg picture   "$IMDB_SCHEMA_PICTURE" \
  --arg director  "$IMDB_SCHEMA_DIRECTOR" \
  --arg creator   "$IMDB_SCHEMA_CREATOR" \
  --arg duration  "$IMDB_SCHEMA_DURATION" \
  --arg type      "$IMDB_SCHEMA_TYPE" \
  --arg id        "$DC_ARG_1" \
  -rc '{
  title: $title,
  original: $original,
  picture: $picture,
  director: $director,
  creator: $creator,
  duration: $duration,
  date: $date,
  year: $year,
  type: $type,
  id: $id,
  properties: .
}')

dc::output::json "$output"

# Call it a day
