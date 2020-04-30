#!/usr/bin/env bash

fs::file::salvage(){
  local file="$1"
  local info

  info="$(file -b "$file")"
  info=${info#*contains:}
  info="${info%%,*}"
  printf "%s" "$info"
}

#xxxfs::file::extract::language() {
#  local file="$1"

#  if dc::wrapped::grep -qi "([, ._(-]+|^)(eng-forced|english-forced|eng[[(_ -]?SDH.?|english[[(_ -]?SDH.?|indonesian|persian|arabic|czech|bul|dan|srp|tur|rus|nor|hun|heb|hrv|fin|pol|est|jpn|cze|chinese|chinese-traditional|croatian|danish|dutch|english|french|german|greek|hebrew|italian|japanese|polish|ru|portuguese|russian|romanian|spanish|swedish|turkish|vietnamese|br|bra|chi|deu|de|dut|eng|en|esp|es|fra|fre|fr|ger|gre|hu|it|ita|nl|nwg|por|pt-br|ptb|ptbr|pt|ro|rum|spa|swe)[)]*\.+[a-z0-9]+" <<<"$file"; then
#    perl -C -Mutf8 -pe 's/(.+[, ._(-]+|^)(eng-forced|english-forced|eng[[(_ -]?SDH.?|english[[(_ -]?SDH.?|indonesian|persian|arabic|czech|bul|dan|srp|tur|rus|nor|hun|heb|hrv|fin|pol|est|jpn|cze|chinese|chinese-traditional|croatian|danish|dutch|english|french|german|greek|hebrew|italian|japanese|polish|ru|portuguese|russian|romanian|spanish|swedish|turkish|vietnamese|br|bra|chi|deu|de|dut|eng|en|esp|es|fra|fre|fr|ger|gre|hu|it|ita|nl|nwg|por|pt-br|ptb|ptbr|pt|ro|rum|spa|swe)[)]*([.]+[a-z0-9]+)+/\2/i' <<<"$file" | tr '[:upper:]' '[:lower:]'
#    perl -C -Mutf8 -pe 's/.+[, ._(-]+(eng[[(-]?SDH.?|czech|bul|dan|srp|tur|rus|nor|hun|heb|hrv|fin|pol|est|jpn|cze|chinese|chinese-traditional|croatian|danish|dutch|english|french|german|greek|hebrew|italian|japanese|polish|ru|portuguese|russian|romanian|spanish|swedish|turkish|vietnamese|br|bra|chi|deu|de|dut|eng|en|esp|es|fra|fre|fr|ger|gre|hu|it|ita|nl|nwg|por|pt-br|ptb|ptbr|pt|ro|rum|spa|swe)[)]*([.]+[a-z0-9]+)+/\1/i' <<<"$file" | tr '[:upper:]' '[:lower:]'
#  fi
#}

fs::file::extract::suffix() {
  local file="$1"

  if dc::wrapped::grep -qi "[,. ]part[ ]*[0-9]+" <<<"$file"; then
    perl -pe 's/.*[,. ]part[ ]*([0-9]+).*/, E\1/i' <<<"$file"
  fi
  if dc::wrapped::grep -qi "[,. ]cd[ ]*[0-9]+" <<<"$file"; then
    perl -pe 's/.*[,. ]cd[ ]*([0-9]+).*/, E\1/i' <<<"$file"
  fi
  if dc::wrapped::grep -qi "[,. ]disc[ ]*[0-9]+" <<<"$file"; then
    perl -pe 's/.*[,. ]disc[ ]*([0-9]+).*/, E\1/i' <<<"$file"
  fi
  if dc::wrapped::grep -qi "(^|.*[ .,_-])season[ .,_-]*[0-9]+[ .,_-]*episode[ .,_-]*[0-9]+" <<<"$file"; then
    perl -pe 's/(^|.*[ .,_-])season[ .,_-]*([0-9]+)[ .,_-]*episode[ .,_-]*([0-9]+).*/, S\2E\3/i' <<<"$file"
  fi

  if dc::wrapped::grep -qi "^(.*[ .,_-]+)?(S[0-9]+)?[ .,_-]*EP?[0-9]+" <<<"$file"; then
    perl -pe 's/^(.*[ .,_-]+)?(S[0-9]+)?[ .,_-]*(EP?[0-9]+).*/, \2\3/i' <<<"$file"
  fi
}

fs::file::extract::base() {
  local file="$1"
  file="${file%.*}"
#  dc::logger::error "Before: $file"
  file="$(sed -E 's/(.+)part [0-9]+.*/\1/' <<<"$file")"
  file="$(sed -E 's/(.+)disc [0-9]+.*/\1/' <<<"$file")"
  file="$(sed -E 's/(.+)E[0-9]+.*/\1/' <<<"$file")"
  file="$(sed -E 's/(.+)S[0-9]+.*/\1/' <<<"$file")"
  file="$(sed -E 's/\[[^]]+]/ /g' <<<"$file")"
  file="$(sed -E 's/\{[^}]+}/ /g' <<<"$file")"
#  file="$(sed -E 's/^Bonus +(.+)/\1/' <<<"$file")"

  file="$(sed -E 's/[.,_;!? -]+/  /g' <<<"$file")"

#  file="$(perl -C -Mutf8 -pe 's/[ ](aac|HD|Eng|Ita|AMZN|WEb DL|DDP2|NTG|Multi[ ]+Subs|ac3|Subs|Criterion|TrueHD|LPCM|flac|hdma|hevc|ddr|[0-9][ ]+[0-9]|blu-ray|x264|720p|BRRip|BluRay|DTS|WEB-DL|AAC5[ ]+1|5[ ]+1CH|5[ ]+1|H[ ]+264|DVDRip|XviD|EVO|HDRip|mkv|HDTV|1080p|mp4|multisubs|WebRip|Reenc|BDRip|DVD5|DVD)([ ]|$)/ /gi' <<<"$file")"
#  file="$(perl -C -Mutf8 -pe 's/(.+[ ]|^)(eng-forced|english-forced|eng[[(_ -]?SDH.?|english[[(_ -]?SDH.?|indonesian|persian|arabic|czech|bul|dan|srp|tur|rus|nor|hun|heb|hrv|fin|pol|est|jpn|cze|chinese|chinese-traditional|croatian|danish|dutch|english|french|german|greek|hebrew|italian|japanese|polish|portuguese|russian|romanian|spanish|swedish|turkish|vietnamese|br|bra|chi|deu|de|dut|eng|en|esp|es|fra|fre|fr|ger|gre|hu|it|ita|nl|nwg|por|pt-br|ptb|ptbr|pt|ro|rum|spa|swe)([ ]|$)/\2/i' <<<"$file")"
  file="$(scene::remove "$file")"
  file="$(language::extract::rest "$file")"


  file="$(sed -E 's/[[:space:]]{2,}/ /g' <<<"$file")"
  file="$(sed -E 's/^[[:space:]]+//' <<<"$file" | sed -E 's/[[:space:]]+$//')"

#  dc::logger::error "No keyword: $file"

  printf "%s" "$file"
}

fs::file::isProtected() {
  local file="$1"
  # XXX suboptimal
  dc::wrapped::grep -qi "(^Bonus|Sample[.]|^Sample)" <<<"$file"
}

refactor::newfilename(){
  local targetBase="$1"
  local data="$2"

  local file
  local currentName
  local newname
  local parent
  local ln=""
  local suffix=""


#   dc::output::json "$data"

  file="$(jq -rc ".data.file" <<<"$data")"
  parent="$(dirname "$file")"
  currentName="$(basename "$file")"
  targetExtension="$(jq -rc ".extension" <<<"$data")"

  local currentExtension="${currentName##*.}"

  [ "$currentExtension" == "$targetExtension" ] || {
    dc::logger::warning "File $currentName has a wrong extension. Will be changed to $targetExtension"
    >&2 dc::output::json "$data"
  }

  # suffix="$(fs::file::extract::suffix "$parent/$currentName")"
  suffix="$(jq -rc ".suffix" <<<"$data")"

  if [ "$targetExtension" == "srt" ] || [ "$targetExtension" == "vob" ] || [ "$targetExtension" == "sub" ] || [ "$targetExtension" == "idx" ] || [ "$targetExtension" == "rar" ] || [ "$targetExtension" == "ass" ] || [ "$targetExtension" == "smi" ]; then
    # ln="$(fs::file::extract::language "$currentName")"
    ln="$(language::extract::lang "$currentName")"
    qual="$(language::extract::qualifier "$currentName")"
    [ ! "$qual" ] || ln="$ln $qual"
    [ ! "$ln" ] || ln=".$ln"
  fi

  newname="$targetBase$suffix$ln.$targetExtension"
  newname="$(iconv -f utf8 -t ascii//TRANSLIT <<<"$newname")"
  newname="$(sed -E 's/\//_/g' <<<"$newname")"
  [ "${newname:0:1}" != "." ] || newname="_$newname"

  if [ "$newname" != "$currentName" ]; then
    dc::logger::warning "     < $currentName"
    dc::logger::warning "     > $newname"
    # XXX this sucks on case sensitive FS that are not really case sensitive (looking at you macOS)
    # Fix: use a temporary [toberenamed] filename THEN check for existence
    if ! dc::wrapped::grep -q "to be renamed" <<<"$currentName"; then
      mv "$parent/$currentName" "$parent/[to be renamed] $currentName"
      currentName="[to be renamed] $currentName"
      sleep 1
    fi
    if [ -e "$parent/$newname" ]; then
      mv "$parent/$currentName" "$parent/${currentName#*] }"
      dc::logger::error "Cannot rename. Destination already exist! Erroring now."
      return
    fi
    dc::prompt::confirm
    mv "$parent/$currentName" "$parent/$newname"
  fi
}

fs::file::recon() {
  local file="$1"
  local prefix="${2:-}"
  local sfile
  sfile="$(basename "$file")"

  local data
  local container
  local video
  local audio
  local subtitle
  local other

  local extension
  local type=""
  local suffix=""
  local language=""
  local protected=""

  local duration=""
  local density=""
  local codec=""
  local width=""
  local height=""

  local salvage

  if ! data="$(fi-movie-info -s "$file")"; then
    salvage="$(fs::file::salvage "$file")"
    case "$salvage" in
      "PDF document")
        type="document"
        extension="pdf"
        protected=true
        container="bypass"
      ;;
      "HTML document text")
        type="document"
        extension="html"
        protected=true
        container="bypass"
      ;;
      "Composite Document File V2 Document")
        type="document"
        extension="doc"
        protected=true
        container="bypass"
      ;;
      *)
        dc::logger::error "$file"
        dc::logger::error " >>> HARD failure <<<"
        dc::error::detail::set "$file"
        return "$ERROR_GENERIC_FAILURE"
      ;;
    esac
  fi

  # XXX dirty bypass
  [ "$container" ] || container="$(jq -r '.container' <<<"$data")"
  video="$(jq -r '.video | length' <<<"$data")"
  audio="$(jq -r '.audio | length' <<<"$data")"
  subtitle="$(jq -r '.subtitles | length' <<<"$data")"
  other="$(jq -r '.other | length' <<<"$data")"

  case "$container" in
  # Subtitles
  "srt")
    extension="srt"
    type="subtitle"
    ;;
  "ass")
    extension="ass"
    type="subtitle"
    ;;
    # XXX these below are rare / not quite clear
  "lrc")
    extension="ass"
    type="subtitle"
    ;;
  "subviewer")
    extension="sub"
    type="subtitle"
    ;;
  "vobsub")
    extension="idx"
    type="subtitle"
    ;;
  "microdvd")
    extension="sub"
    type="subtitle"
    ;;
  "sami")
    extension="smi"
    type="subtitle"
    ;;

    # Mixed
  "mpeg")
    if [ "$video" == 0 ]; then
      type="subtitle"
      extension="sub"
    else
      type="movie"
      extension="mpeg"
      if [ "$(jq -r .other[0].codec_name <<<"$data")" == "dvd_nav_packet" ]; then
        extension="iso"
      fi
    fi
    ;;

    # Images
  "png_pipe")
    extension="png"
    type="image"
    ;;
  "image2")
    extension="jpg"
    type="image"
    ;;
  "jpeg_pipe")
    extension="jpg"
    type="image"
    ;;
  "tty")
    extension="nfo"
    type="image"
    ;;
  "gif")
    extension="gif"
    type="image"
    ;;

    # Audio
  "mp3")
    extension="mp3"
    type="sound"
    protected=true
    ;;
    # Movies
  "matroska,webm")
    type="movie"
    extension="mkv"
    ;;
  "avi")
    type="movie"
    extension="avi"
    ;;
  "mov,mp4,m4a,3gp,3g2,mj2")
    type="movie"
    extension="mp4"
    ;;
  "ogg")
    type="movie"
    extension="ogv"
    ;;
  "asf")
    type="movie"
    extension="wmv"
    ;;

  # XXX very dirty catchall for pre processed file-d docs
  "bypass")
    true
    ;;
  *)
    dc::logger::error "UNKNOWN CONTAINER TYPE $container"
    >&2 jq -r <<<"$data"
    return "$ERROR_GENERIC_FAILURE"
    ;;
  esac

  case "$type" in
  "subtitle")
    [ "$subtitle" -ge 1 ] || {
#      >&2 jq -r <<<"$data"
      dc::logger::error "$file"
      dc::error::detail::set "$file"
      dc::logger::error " >>> Subtitle file has no subtitle streams. This is pretty useless... <<<"
#      return "$ERROR_GENERIC_FAILURE"
    }
    [ "$audio" == 0 ] || {
#      >&2 jq -r <<<"$data"
      dc::logger::error "$file"
      dc::error::detail::set "$file"
      dc::logger::error " >>> Subtitle file with audio streams. This is usually useless... <<<"
#      dc::error::detail::set "$file"
#      return "$ERROR_GENERIC_FAILURE"
    }
    [ "$video" == 0 ] || {
      >&2 jq -r <<<"$data"
      dc::logger::error "Subtitle file with video streams. WTF"
      dc::error::detail::set "$file"
      return "$ERROR_GENERIC_FAILURE"
    }
    #[ "$other" == 0 ] || {
    #  jq -r <<<"$data"
    #  echo "ERRORRRRRR"
    #  exit 1
    #}
    # language="$(fs::file::extract::language "$sfile")"
    language="$(language::extract::lang "$sfile")"
    ;;
  "image")
    [ "$subtitle" == 0 ] || {
      >&2 jq -r <<<"$data"
      dc::logger::error "Image file with subtitle streams"
      dc::error::detail::set "$file"
      return "$ERROR_GENERIC_FAILURE"
    }
    [ "$audio" == 0 ] || {
      jq -r <<<"$data"
      dc::logger::error "Image file with audio streams"
      dc::error::detail::set "$file"
      return "$ERROR_GENERIC_FAILURE"
    }
    [ "$video" == 1 ] || {
      jq -r <<<"$data"
      dc::logger::error "Image file with the wrong number of video streams"
      dc::error::detail::set "$file"
      return "$ERROR_GENERIC_FAILURE"
    }
    [ "$other" == 0 ] || {
      jq -r <<<"$data"
      dc::logger::error "Image file with the random streams"
      dc::error::detail::set "$file"
      return "$ERROR_GENERIC_FAILURE"
    }
    ;;
  "movie")
    [ "$video" -ge 1 ] || {
      jq -r <<<"$data"
      dc::logger::error "Movie file with no video"
      dc::error::detail::set "$file"
      return "$ERROR_GENERIC_FAILURE"
    }

    # XXX in some rare cases, ISO dvd will not report a container duration properly (hance movie-info will report 0)
    duration="$(printf "%s" "$data" | jq -r -c '(.duration|tonumber) / 60 | floor')"
    if [ "$duration" != 0 ]; then
      density="$(printf "%s" "$data" | jq -r -c '(.size|tonumber) / (.duration|tonumber) / .video[0].width / .video[0].height')"
      density="$(printf "%s\\n" "scale=2;$density/1" | bc)"
    fi
    # XXX this obviously fails with multistream videos (rv40 / embedded mjpeg)
    codec="$(printf "%s" "$data" | jq -r -c '.video[0] | .codec')"
    width="$(printf "%s" "$data" | jq -r -c '.video[0] | (.width|tostring)')"
    height="$(printf "%s" "$data" | jq -r -c '.video[0] | (.height|tostring)')"
    ;;
  esac

  suffix="$(fs::file::extract::suffix "$sfile")"
  ! fs::file::isProtected "$sfile" || protected=true

  # XXX wtf?
  printf "%s" "$prefix"
  return=$(printf "%s" "$data" | jq \
    --arg file "$file" \
    --arg extension "$extension" \
    --arg suffix "$suffix" \
    --arg type "$type" \
    --arg language "$language" \
    --arg protected "$protected" \
    --arg density "$density" \
    --arg duration "$duration" \
    --arg codec "$codec" \
    --arg width "$width" \
    --arg height "$height" \
    --arg base "$(fs::file::extract::base "$sfile")" \
    -r '{
    extension: $extension,
    suffix: $suffix,
    language: $language,
    type: $type,
    base: $base,
    protected: $protected,
    duration: $duration,
    density: $density,
    codec: $codec,
    width: $width,
    height: $height,
    data: .
  }')
  dc::output::json "$return"
}

fs::dir::recon() {
  local obj="$1"
  local sep="${2:-}"
  local norewrap="${3:-}"
  local i
  local close=""
  [ "$sep" ] || [ "$norewrap" ] || {
    printf "["
    close=tru
  }
  #  dc::logger::info "$obj"
  for i in "$obj"/*; do
    if [ ! -f "$i" ]; then
      # XXX if the folder yields no file, this will fail
      if ! dc::wrapped::grep -qi "^Bonus" <<<"$(basename "$i")"; then
        fs::dir::recon "$i" "$sep" "no rewrap"
        sep=","
      fi
      continue
    fi

    fs::file::recon "$i" "$sep" && sep="," || {
      true
      dc::logger::error " |||| will be left untouched ($i) ||||"
      # return "$ERROR_GENERIC_FAILURE"
    }
  done
  [ ! "$close" ] || {
    printf "]"
  }
}

refactor::newdirname() {
  local parent="$1"
  local oldname="$2"
  local id="$3"
  local year="$4"
  local title="$5"
  local durationInfo="$6"
  local supplemental="$7"
  local newname="($year) $title [$id] [$durationInfo] [$supplemental]"
  newname="$(iconv -f utf8 -t ascii//TRANSLIT <<<"$newname")"
  newname="$(sed -E 's/\//_/g' <<<"$newname")"
  if [ "$newname" != "$oldname" ]; then
    dc::logger::warning "< $oldname"
    dc::logger::warning "> $newname"
    if [ -e "$parent/$newname" ]; then
      dc::logger::error "Destination already exist! Abort!"
      return 1
    fi
#    dc::prompt::confirm
    mv "$parent/$oldname" "$parent/$newname"
  fi
}
