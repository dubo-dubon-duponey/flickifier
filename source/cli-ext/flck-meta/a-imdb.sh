_DC_PRIVATE_CACHE_BUST=
_DC_PRIVATE_UA="dbdbdp"

flck::cachebust(){
  _DC_PRIVATE_CACHE_BUST=true
}

flck::ua(){
  _DC_PRIVATE_UA="$1"
}

flck::requestor() {
  local url="$1"
  local method="GET"
  [ ! "$_DC_PRIVATE_CACHE_BUST" ] || dc-ext::sqlite::delete "dchttp" "url=\"$url\" AND method=\"$method\""

  dc::logger::debug "Requestor to fetch url $url"
  dc-ext::http-cache::request "$url" "$method" "" "" "User-Agent: $_DC_PRIVATE_UA" | dc::wrapped::base64d | tr '\n' ' ' | tr '\r' ' ' || return "$ERROR_NETWORK"
}

flck::requestor::imdb() {
  local endpoint="$1"
  flck::requestor "https://www.imdb.com/$endpoint" |
    perl -pe 's/<style[^>]*>([^<]*|<[^\/])*<\/style>//g' |
    perl -pe 's/<iframe[^>]*>([^<]*|<[^\/])*<\/iframe>//g' |
    perl -pe 's/<svg[^>]*>([^<]*|<[^\/]|<\/[^s])*<\/svg>//g' |
    perl -pe 's/itemscope /itemscope="" /g' |
    perl -pe 's/&nbsp;/ /g' |
    perl -pe 's/&raquo;/>/g'
}

# Will throw on no result
flck::requestor::imdb::search::title() {
  local question
  local year="${2:-}"

  question="$(dc::encoding::uriencode "$1")"
  [ ! "$year" ] || {
    dc::argument::check year "^[0-9]{4}$"
    year="&release_date=$year-01-01,$year-12-31"
  }

  local response

  response="$(
    flck::requestor::imdb "search/title/?title=$question$year&adult=include" |
      perl -pe 's/(<div class="lister-item mode-advanced">)/\n\1/g' |
      dc::wrapped::grep '^<div class="lister-item mode-advanced">'
  )"

  local line
  local director
  local runtime

  local sep=""

  printf "["
  while read -r line; do
    [ "$line" ] || continue

    printf "%s{" "$sep"

    # XXX imdb does not escape quotes in alt attributes, breaking the search here
    perl -pe 's/.*<a href="\/title\/(tt[0-9]{7,})[^>]+>[^<]*<img alt="([^"]*)[^>]*loadlate="([^"]+).*/"id": "\1", "title": "\2", "picture": "\3",/' <<<"$line"

    year="$(perl -pe 's/.*<span class="lister-item-year text-muted unbold">([^<]*[(]([0-9]*)[^)]*[)])?.*/\2/' <<<"$line")"
    printf '"year": "%s",' "$year"

    ! dc::wrapped::grep -q 'Director: ' <<<"$line" || director="$(perl -pe 's/.*Director: <a href="\/name\/(nm[0-9]{7,})[^>]+>([^<]*).*/\2/' <<<"$line")"
    printf '"director": "%s",' "$director"

    ! dc::wrapped::grep -q '<span class="runtime">' <<<"$line" || {
      dc::wrapped::grep -Eq '[0-9] min' <<<"$line" || {
        dc::logger::error "Unexpected runtime format"
        exit "$ERROR_GENERIC_FAILURE"
      }
      runtime="$(perl -pe 's/.*<span class="runtime">(.*?) min<\/span>.*/\1/' <<<"$line")"
    }
    printf '"runtime": "%s"' "$runtime"

    printf "}"
    sep=","
  done <<<"$response"

  printf "]"
}

flck::requestor::imdb::search::name() {
  local question="$1"

  local response
  local line

  local sep=""

  response="$(
    flck::requestor::imdb "search/name/?name=$(dc::encoding::uriencode "$question")&adult=include" |
      perl -pe 's/(<div class="lister-item mode-detail">)/\n\1/g' |
      dc::wrapped::grep '^<div class="lister-item mode-detail">'
  )"

  printf "["
  while read -r line; do
    [ "$line" ] || continue

    printf "%s{" "$sep"

    ! dc::wrapped::grep -Eq '<p class="text-muted text-small">[^<]*<span class="ghost">[|]' <<<"$line" || {
      # XXX whitespace handling not the most elegant or functioning ever...
      perl -pe 's/.*<p class="text-muted text-small">[ ]*([^<]+)[ ]*<span class="ghost">[|]<\/span>[^<]*<a[^>]+>[ ]*([^<]+).*/"known": "\1 \2",/' <<<"$line"
    }

    perl -pe 's/.*<a href="\/name\/(nm[0-9]{7,})[^>]*>[^<]*<img alt="([^"]+)[^>]*src="([^"]+).*/"id": "\1", "name": "\2", "picture": "\3"/' <<<"$line"

    printf "}"
    sep=","
  done <<<"$response"

  printf "]"
}

flck::requestor::imdb::get::title::techspecs() {
  local identifier="$1"
  local response

  local schema

  local schema_title
  local schema_picture
  local schema_type
  local schema_date
  local schema_director
  local schema_creator
  local schema_duration

  local cleaned

  local year
  local title

  response="$(
    flck::requestor::imdb "title/$identifier/technical" |
      perl -pe 's/(<tbody[^>]*>.*<\/tbody>).*/\n\1\n/i' |
      dc::wrapped::grep "^<tbody"
    #      perl -pe 's/(<div class="lister-item mode-detail">)/\n\1/g' |
    #      dc::wrapped::grep '^<div class="lister-item mode-detail">'
  )"

#  >&2 echo "-> treating $response"
  local line
  local sep
  local key
  local value
  local ar=""
  local i

  while
    line=${response%%"</tr>"*}
    [ "$line" != "$response" ]
  do
    sep='<td class="label">'
    line=${line#*"$sep"}
    response=${response#*"</tr>"}
    key=${line%%"</td>"*}
    value=${line#*"<td>"}
    value=${value%%"</td>"*}
    # XXX sed will introduce a trailing line feed
    key="$(perl -pe 's/[[:space:]]*$//' <<<"$key" | perl -pe 's/^[[:space:]]*//' | tr -d '\n' | tr '[:lower:]' '[:upper:]' | tr '[:space:]' '_')"

    printf '%s"%s": [' "$ar" "$key"
    ar=", "

    ec=""
    # >&2 printf ">>>>%s<<<" "$value"
    if [ "$key" == "SOUND_MIX" ] || [ "$key" == "COLOR" ]; then
      sep='<span class="ghost">|</span>'
      while IFS= read -r -d '' i; do
        i="$(perl -pe 's/<[^>]+>//g' <<<"$i" | perl -pe 's/[[:space:]]*$//' | perl -pe 's/^[[:space:]]*//' | perl -pe 's/[[:space:]]{2,}/ /g')"
        printf '%s"%s"' "$ec" "$(perl -pe 's/"/\\"/g' <<<"$i")"
        ec=", "
      done < <(dc::string::split value sep)
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
        ! dc::wrapped::grep -q "([0-9]+) hr" <<<"$i" || hr="$(perl -pe 's/.*([0-9]+) hr.*/\1/' <<<"$i")"
        ! dc::wrapped::grep -q "([0-9]+) min[^)]" <<<"$i" || min="$(perl -pe 's/(.*[[:space:]*])?([0-9]+) min.*/\2/' <<<"$i")"
        ! dc::wrapped::grep -q "([0-9]+) sec" <<<"$i" || sec="$(perl -pe 's/(.*[[:space:]*])?([0-9]+) sec.*/\2/' <<<"$i")"

        rest="$(perl -pe 's/[^(]+([(][0-9]+ min[)] )?(.*)/\2/' <<<"$i" | perl -pe 's/[[:space:]]*$//' | perl -pe 's/"/\\"/g')"

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
      done < <(dc::string::split value sep)
    else
      sep="<br>"
      while IFS= read -r -d '' i; do
        i="$(printf "%s" "$i" | sed -E 's/<[^>]+>//g' | sed -E 's/[[:space:]]*$//' | sed -E 's/^[[:space:]]*//' | sed -E 's/[[:space:]]{2,}/ /g')"
        printf '%s"%s"' "$ec" "$(perl -pe 's/"/\\"/g' <<<"$i")"
#        printf '%s"%s"' "$ec" "$i"
        ec=", "
      done < <(dc::string::split value sep)
    fi
    printf "]"
  done
}

flck::requestor::imdb::get::title::episodes() {
  local identifier="$1"
  local season="$2"

  local response
  local episodes

  response="$(flck::requestor::imdb "title/$identifier/episodes?season=$season")"

  # Episodes are not &quot protected
#  episodes="$(perl -pe "s/\/title\/(tt[0-9]{7,})\/[?]ref_=ttep_ep([0-9]+)[^>]+title=\"([^\"]+)\" itemprop=\"name\"/\n,{\"id\": \"\1\", \"number\": \"\2\", \"title\": \"\3\"}\n/g" <<<"$response" | dc::wrapped::grep -E "^,{\"id\"")"

  printf "["
  local sep=""
  while read -r item; do
    episodes="$(perl -pe "s/.*itemprop=\"episodeNumber\" content=\"([^\"]+).*\/title\/(tt[0-9]{7,})[^>]+title=\"([^\"]+)\" itemprop=\"name\"/\n{\"id\": \"\2\", \"number\": \"\1\", \"title\": \"\3\"}\n/g" <<<"$item" | dc::wrapped::grep "^{\"id\"")"
#    if [ "$episodes" ]; then
      printf "%s%s" "$sep" "$(perl -pe "s/&quot;/\\\\\"/"<<<"$episodes")"
      sep=","
#    fi
  done < <(perl -pe 's/(<div class="info" itemprop="episodes")/\n\1/g' <<<"$response" | dc::wrapped::grep '^<div class="info" itemprop="episodes"' )
  #
  printf "]"
}

flck::requestor::imdb::get::title() {
  local identifier="$1"
  local response

  local schema

  local schema_title
  local schema_picture
  local schema_type
  local schema_date
  local schema_director
  local schema_creator
  local schema_duration

  local cleaned

  local year
  local title

  local parts

  local line

  response="$(flck::requestor::imdb "title/$identifier/")" || return

  # Extract the shema.org section, then the original title and picture url
  schema="$(perl -pe 's/.*<script type="application\/ld[+]json">([^<]+).*/\1/' <<<"$response")"

  schema_title="$(jq -r '.name' <<<"$schema")"
  schema_picture="$(jq -r 'select(.image != null).image' <<<"$schema")"
  schema_type="$(jq -r '."@type"' <<<"$schema")"
  schema_date="$(jq -r 'select(.datePublished != null).datePublished' <<<"$schema")"
  # dc::output::json "$schema"
  schema_director="$(jq -r 'select(.director != null).director | if type=="array" then .[0].name else .name end' <<<"$schema")"
  schema_creator="$(jq -r 'select(.creator != null).creator | if type=="array" then .[0] else . end | select(.name != null).name' <<<"$schema")"
  schema_duration="$(jq -r 'select(.duration != null).duration' <<<"$schema")"

  # Process the body to get the title, year and type
  cleaned="$(perl -pe "s/.*<meta property='og:title'[^>]+content=\"([^\"]+).*/\1/" <<<"$response")"
  year="$(perl -pe "s/^.*[(][^)–]*([0-9]{4}[0-9– ]*)[)].*/\1/" <<<"$cleaned")"
  year="${year%–*}"
  title="$(perl -pe "s/^(.*)[[:space:]]+[(][^)]*[0-9]{4}[0-9– ]*[)].*/\1/" <<<"$cleaned")"

  eps="{"

  if parts="$(perl -pe "s/(\/title\/$identifier\/episodes[?]season=[^&]+)/\n\1\n/g" <<<"$response" | dc::wrapped::grep "\/title\/$identifier\/episodes[?]season=")"; then
    sep=""
    while read -r line; do
      eps+="$(printf '%s"%s": ' "$sep" "$(perl -pe "s/.*season=([^&]+).*/\1/" <<<"$line")")"
      sep=","
      eps+="$(flck::requestor::imdb::get::title::episodes "$identifier" "$(perl -pe "s/.*season=([^&]+).*/\1/" <<<"$line")")"
    done < <(printf "%s\n" "$parts")
  fi

  eps+="}"

  #       perl -pe 's/&quot;/"/g' |
  # cleaned=$(printf "%s" "${response}" | perl -pe "s/.*<meta property='og:type' ([^>]+).*/\1/" | perl -pe 's/.*content=\"([^\"]+)\".*/\1/')
  # TYPE=$(printf "%s" "$cleaned")

  title="$(perl -pe 's/&quot;/"/g' <<<"$title")"
  schema_title="$(perl -pe 's/&quot;/"/g' <<<"$schema_title")"

  # >&2 flck::requestor::imdb::get::title::techspecs "$identifier"

  printf "{%s}" "$(flck::requestor::imdb::get::title::techspecs "$identifier")" | jq \
    --arg title "$title" \
    --arg year "$year" \
    --arg date "$schema_date" \
    --arg original "$schema_title" \
    --arg picture "$schema_picture" \
    --arg director "$schema_director" \
    --arg creator "$schema_creator" \
    --arg duration "$schema_duration" \
    --arg type "$schema_type" \
    --arg id "$identifier" \
    --argjson parts "$eps" \
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
    parts: $parts,
    properties: .
  }'

}

flck::requestor::imdb::get::name() {
  local identifier="$1"
  local as="${2:-director}"
  local response

  local schema

  local schema_title
  local schema_picture
  local schema_type
  local schema_date
  local schema_director
  local schema_creator
  local schema_duration

  local cleaned

  local year
  local title

  local parts

  local line

  response="$(flck::requestor::imdb "name/$identifier/")" || return

  # Extract the shema.org section, then the original title and picture url
  schema="$(perl -pe 's/.*<script type="application\/ld[+]json">([^<]+).*/\1/' <<<"$response")"

  schema_title="$(jq -r '.name' <<<"$schema")"
  schema_picture="$(jq -r 'select(.image != null).image' <<<"$schema")"
  schema_type="$(jq -r '."@type"' <<<"$schema")"

  # Break on the various credit types: writer, director, producer, soundtrack, sound_department, visual_effects, editorial_department, cinematographer, editor, composer, actor, self, etc
  parts="$(perl -pe 's/(<div id="filmo-head)/\n\1/g' <<<"$response" | dc::wrapped::grep "^<div id=\"filmo-head-$as\"" | perl -pe 's/<b><a href="\/title\/(tt[0-9]{7,})[^>]*>([^<]+)/\n,{"id": "\1", "title": "\2"}\n/g' | dc::wrapped::grep "^,{\"id\":")"

#  echo "["${parts:1}"]"

  # cleaned=$(printf "%s" "${response}" | perl -pe "s/.*<meta property='og:type' ([^>]+).*/\1/" | perl -pe 's/.*content=\"([^\"]+)\".*/\1/')
  # TYPE=$(printf "%s" "$cleaned")

  jq \
    --arg title "$schema_title" \
    --arg picture "$schema_picture" \
    --arg type "$schema_type" \
    --arg id "$identifier" \
    --argjson parts "{\"$as\": [${parts:1}]}" \
    -rc '{
    name: $title,
    picture: $picture,
    type: $type,
    id: $id,
    movies: $parts
  }' <<<"{}"

}
