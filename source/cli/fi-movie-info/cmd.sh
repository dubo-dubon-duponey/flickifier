#!/usr/bin/env bash

true
# shellcheck disable=SC2034
readonly CLI_VERSION="0.1.0"
# shellcheck disable=SC2034
readonly CLI_LICENSE="MIT License"
# shellcheck disable=SC2034
readonly CLI_DESC="spits out information about media files in a json format (duration, container, size, and for each track, codec, resolution or language)"

# Initialize
dc::commander::initialize
dc::commander::declare::arg 1 ".+" "filename" "media file to be analyzed"
# Start commander
dc::commander::boot
# Requirements
dc::require jq
dc::require ffprobe
dc::require mp4info || dc::logger::warning "MP4info is recommended (and missing - install bento4)"

# Argument 1 is mandatory and must be a readable file
dc::fs::isfile "$DC_ARG_1"

filename="$DC_ARG_1"
dc::logger::info "[movie-info] $filename"


info::ffprobe(){
  local comprobe=ffprobe
  # XXX avprobe is an entirely different thing, not implementing support for this s.

  local data
  local fast=false
  local duration
  local return

  dc::logger::debug "$comprobe -show_format -show_error -show_data -show_streams  -print_format json \"$1\" 2>/dev/null)"


  if ! data="$($comprobe -show_format -show_error -show_data -show_streams -print_format json "$1" 2>/dev/null)"; then
    # XXX review this to see what other info we should return (filesize?)
    dc::output::json "{\"file\":\"$1\"}"
    dc::error::detail::set "$1"
    dc::logger::error "ffprobe is unable to analyze this file. Not a movie. Stopping here."
    exit "$ERROR_GENERIC_FAILURE"
  fi

  if [ "$(printf "%s" "$data" | jq -r .error)" != "null" ]; then
    dc::error::detail::set "$data"
    dc::logger::error "ffprobe output is not valid json. Stopping here."
    exit "$ERROR_GENERIC_FAILURE"
  fi


  local mp4infoisborked
  if ! mp4infoisborked="$(mp4info --format json "$1" 2>/dev/null)"; then
    dc::logger::error "mp4info errored out or is not available. faststart information will be inaccurate."
    fast=false
  fi

  if ! fast=$(printf "%s" "$mp4infoisborked" | tr -d '\n' | sed -E 's/,[[:space:]]*}/}/g' | jq -r '.file | select(.fast_start != null).fast_start' 2>/dev/null); then
    dc::logger::error "mp4info output is not valid json. faststart information will be inaccurate."
    fast=false
  fi

  duration=$(printf "%s" "$data" | jq '.format | select(.duration != null) | .duration | tonumber | floor')
  if [ ! "$duration" ]; then
    duration=0
  fi

  return=$(printf "%s" "$data" | jq --arg fast "$fast" --arg duration "$duration" -r '{
    file: .format.filename,
    size: .format.size,
    container: .format.format_name,
    description: .format.format_long_name,
    fast: $fast,
    duration: $duration,
    video: [
      .streams[] | select (.codec_type == "video") | {
        id: .index,
        codec: .codec_name,
        description: .codec_long_name,
        width: .width,
        height: .height
      }
    ],
    audio: [
      .streams[] | select (.codec_type == "audio") | {
        id: .index,
        codec: .codec_name,
        description: .codec_long_name,
        language: .tags.language
      }
    ],
    subtitles: [
      .streams[] | select (.codec_type == "subtitle") | {
        id: .index,
        codec: .codec_name,
        description: .codec_long_name,
        language: .tags.language
      }
    ],
    other: [
      .streams[] | select ((.codec_type == "video"|not) and (.codec_type == "audio"|not) and (.codec_type == "subtitle"|not))
    ]
  }')
  dc::logger::debug "Returned data: $return"
  dc::output::json "$return"
}

info::ffprobe "$filename"
