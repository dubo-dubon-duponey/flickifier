#!/usr/bin/env bash

# dc::http::request "https://iso639-2.sil.org/sites/iso639-2/files/downloads/iso-639-2.tab" GET
# dc::http::request "https://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt" GET

true
# shellcheck disable=SC2034
readonly CLI_VERSION="0.1.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="movies filesystem organizer"

# Boot
dc::commander::initialize
dc::commander::declare::arg 1 ".+" "directory" "the directory to analyze. The name must contain an imdb identifier (eg: tt0000001)"
# Start commander
dc::commander::boot

# Requirements
dc::require flck-meta
dc::require fi-movie-info

# Force to info for now
dc::logger::level::set::info

# Argument 1 is mandatory and must be a readable directory
dc::fs::isdir "$DC_ARG_1"

currentdir="$DC_ARG_1"
directory="$(basename "$DC_ARG_1")"
parent="$(dirname "$DC_ARG_1")"

dc::logger::info ">>>>>> $directory <<<<<<"

result="$(fs::dir::recon "$DC_ARG_1")"

# dc::output::json "$result"

renamableFiles="$(jq '[.[] | select(.type != "image") | select(.protected != "true")]' <<<"$result")"
nonBonusMovies="$(jq '[.[] | select(.type == "movie")]' <<<"$renamableFiles")"
nbMovies="$(jq '. | length' <<<"$nonBonusMovies")"

if [ "$nbMovies" == 0 ]; then
  dc::logger::error "Folder $DC_ARG_1 does not contain ANY movie. Ending now."
  exit "$ERROR_GENERIC_FAILURE"
fi

duration="$(jq -r '.[].duration' <<<"$nonBonusMovies")"

totalDuration=0
for i in $duration; do
  totalDuration=$((totalDuration + i))
done

# Extract id from directory
imdbID="$(printf "%s" "$directory" | perl -pe 's/.*(tt[0-9]{7,})(.*|$)/\1/')"

if ! dc::wrapped::grep -q "tt[0-9]{7,}" <<<"$directory"; then
  candidate="$(jq -r '.[0].base' <<<"$nonBonusMovies" | perl -pe 's/(.*)([(].*)$/\1/')"

  confirm=""
  while [ "$confirm" != "y" ]; do
    args=(flck-meta)
    year=""
    if dc::wrapped::grep -q "[0-9]{4}$" <<<"$candidate"; then
      year="$(perl -pe 's/.* ([0-9]{4})$/\1/' <<<"$candidate")"
      args+=(--year="$year")
      candidate="$(perl -pe 's/[ ]+[0-9]{4}$//' <<<"$candidate")"
    fi
    args+=("$candidate")

    result="$("${args[@]}")"

    length="$(jq length <<<"$result")"

    for (( i=0; i<length; i++ )); do
      [ "$i" -lt 3 ] || break
      jq ".[$i]" <<<"$result"
      dc::prompt::question "Is this ^ what you were looking for? Type 'y' if yes, leave empty otherwise for more results: " confirm
      [ "$confirm" != "y" ] || break
    done
    if [ "$confirm" != "y" ]; then
      dc::prompt::question "Provide a title to search for, optionnally followed by a release date: " candidate
    fi
  done

  imdbID="$(jq -rc ".[$i].id" <<<"$result")"
fi

# Fetch data
if ! imdb=$(flck-meta "$imdbID"); then
  dc::logger::error "Could not retrieve information from imdb for id $imdbID and directory $directory. Aborting!"
  exit "$ERROR_GENERIC_FAILURE"
fi

imdbYear="$(jq -r -c .year <<<"$imdb")"
imdbTitle="$(jq -r -c .title <<<"$imdb")"
imdbOriginal="$(jq -r -c .original <<<"$imdb")"

imdbRuntime="$(jq -rc 'select(.properties.RUNTIME != null).properties.RUNTIME[]' <<<"$imdb")"
runtime=$(sed -E 's/([0-9]+).*/\1/g' <<<"$imdbRuntime")
# XXX limit this to 200 characters? This is weak - better do a limitation on the total path instead
imdbRuntime="$(printf "%s" "$imdbRuntime" | tr '\n' '|')"
if [ "${#imdbRuntime}" -gt 100 ]; then
  imdbRuntime="${imdbRuntime:0:100}..."
fi

withDiff=" KO"
matching="$totalDuration"
for i in $runtime; do
  delta=$(printf "%s\\n" "scale=0;$totalDuration - $i" | bc)
  jitter=$(printf "%s\\n" "scale=0;($totalDuration - $i) * 100 / $i" | bc)

  if [ "$delta" == "0" ]; then
    matching="$totalDuration"
    withDiff=""
    break
  fi
  if { [ "$delta" -gt 2 ] || [ "$delta" -lt -2 ]; } || { [ "$jitter" -gt 10 ] || [ "$jitter" -lt -10 ]; }; then
    continue
  fi

  # dc::logger::warning "Found a duration with less than 2 mins difference and less than 2% time difference overall. Best match so far, but continuing."
  matching="$totalDuration"
  withDiff=" ~"
done


#printf "Renamable files: $(jq '.[].file' <<<"$renamableFiles") \n"
#printf "Number of movies: $nbMovies \n"
#printf "Total Duration: $totalDuration \n"
#printf "Has match: $matching ($imdbRuntime)\n"
#printf "New directory base: "
# printf "Renamable files: $(jq '[.[] | select(.type != "image") | select(.protected != "true") | .base ]' <<<"$result") \n"

# printf "%s" "$nonBonusMovies"


c="$(printf "%s" "$nonBonusMovies" | jq -r -c '.[0] | .codec')"
w="$(printf "%s" "$nonBonusMovies" | jq -r -c '.[0] | (.width|tostring)')"
h="$(printf "%s" "$nonBonusMovies" | jq -r -c '.[0] | (.height|tostring)')"
if [ "$c" != "hevc" ] && [ "$c" != "h264" ]; then
  dc::logger::error "    > codec: $c"
fi
res=""
if [ "$h" -le 500 ] && [ "$w" -le 600 ]; then
  dc::logger::error "    > res: LD"
#  res="LD"
elif [ "$h" -le 576 ] && [ "$w" -le 720 ]; then
  dc::logger::error "    > res: MD"
#  res="MD"
elif [ "$w" -le 1280 ]; then
  dc::logger::warning "    > res: HD"
#  res="HD"
#else
#  dc::logger::info "    > res: Ultra HD"
#  res="uHD"
fi


# Does it have parts?
parts="$(jq -rc '.parts | . as $in| keys[] | $in[.] | .[]' <<<"$imdb")"
seasons="$(jq -rc '.parts | [. as $in| keys[]]' <<<"$imdb")"
nbseasons="$(jq -rc '.parts | [. as $in| keys[]] | length' <<<"$imdb")"
nbparts="$(jq -rc '.parts | [. as $in| keys[] | $in[.] | .[].id] | length' <<<"$imdb")" #  | wc -l
nbparts="${nbparts#* }"
if [ "$nbparts" != "0" ]; then
  nbnb="$(jq length <<<"$nonBonusMovies")"
  if [ "$nbparts" != "$nbnb" ]; then
    dc::logger::error "WO. Stop here. We have a tvshow here (with $nbparts episodes), but you don't have the right number of episodes to match ($nbnb). We'll try our best, but this is likely missing content."
    # exit 1
  fi
fi

density="$(jq -rc '.[0].density' <<<"$nonBonusMovies")"
supplemental="$c-${w}x${h}"
# $(printf "%s" "$nonBonusMovies" | jq -r -c '.[0] | .codec + "-" + (.width|tostring) + "x" + (.height|tostring)' | tr -d '\n')"
supplemental="$supplemental-$(printf "%s" "$nonBonusMovies" | jq -r -c '.[0].data.audio[] | "(" + (.id|tostring) + ")-" + .codec + "-" + .language' | tr -d '\n')-$density"

if [ "$imdbOriginal" == "$imdbTitle" ]; then
  imdbOriginal=
else
  imdbOriginal=" [$imdbOriginal]"
fi

# printf "%s" "$renamableFiles"
total=$(jq -rc '. | length' <<<"$renamableFiles")
for (( i=0; i<$total; i++ )); do
  # Analyze suffix
  suf="$(jq -rc ".[$i].suffix" <<<"$renamableFiles")"
  ep="$(perl -pe 's/[^0-9]+(S[0]?([0-9]+))?EP?[0]?([0-9]+)/\3/i' <<<"$suf")"
  se="$(perl -pe 's/[^0-9]+(S[0]?([0-9]+))?EP?[0]?([0-9]+)/\2/i' <<<"$suf")"
  # No season? Default to default season then
  if [ ! "$se" ]; then
    se="1"
  fi
  dot="$(jq -rc ".[$i]" <<<"$renamableFiles")"
  if [ "$ep" ] && [ "$nbparts" != "0" ]; then
    echo "suffix currently is: $suf"
    echo "got $nbparts parts advertised and this file has an ep marker: $ep - for season $se - parts below"
    jq -rc ".parts" <<<"$imdb"
#    echo "---"
#    echo "suffix: $suf"
#    echo "season: $se"
#    echo "episode: $ep"
#    echo "parts: $parts"
    that="$(jq ".parts.\"$se\" | .[] | select(.number == \"$ep\")" <<<"$imdb")"
    suffix=", S$(printf "%02d" "${se}")E$(printf "%02d" "${ep}") $(jq -rc .title <<<"$that") [$(jq -rc .id <<<"$that")]"
    dot="$(jq --arg suffix "$suffix" '. + {suffix: $suffix}' <<<"$dot")"
#    dc::output::json "$dot"
#    echo "---"
  fi

  refactor::newfilename "$imdbTitle" "$dot"
done


#echo "-----------------"
tp="$(jq -rc .type <<<"$imdb")"
if [ "$tp" != "Movie" ]; then
  dc::logger::error "This is NOT a movie - inspect"
fi
# echo "-----------------"

refactor::newdirname "$parent" "$directory" "$imdbID" "$imdbYear" "$imdbTitle$imdbOriginal" "$matching$withDiff ($imdbRuntime)" "$supplemental"


#while read -r line; do
#  echo ">>> $line"
#done < <(jq -rc '[.[].data.file]' <<<"$renamableFiles")

