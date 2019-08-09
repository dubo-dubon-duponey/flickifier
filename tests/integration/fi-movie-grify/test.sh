#!/usr/bin/env bash

testMovieGrify(){
  if ! _=$(dc::require ffmpeg "-version" 3.0); then
    startSkipping
  fi

  local result

  [ ! -f "tests/integration/fi-movie-grify/movie.mp4" ] || rm "tests/integration/fi-movie-grify/movie.mp4"
#  ffmpeg -i tests/integration/fi-movie-grify/movie.avi -movflags faststart -map 0 -c copy -map -0:1 -map 0:1 -c:a:0 libfdk_aac -b:a 256k tests/integration/fi-movie-grify/movie.mp4

  # [ ! -f "tests/integration/fi-movie-grify/movie.mp4" ] || rm "tests/integration/fi-movie-grify/movie.mp4"
  # XXX remove conversion for libfdk_aac is not on linuxes --convert=1
  result=$(fi-movie-grify --destination=tests/integration/fi-movie-grify --remove=1 tests/integration/fi-movie-grify/movie.avi)
  local exit=$?
  dc-tools::assert::equal "$exit" "0"
  dc-tools::assert::equal "$result" ""

  [ ! -f "tests/integration/fi-movie-grify/movie.mp4" ] || rm "tests/integration/fi-movie-grify/movie.mp4"

  if ! _=$(dc::require ffmpeg "-version" 3.0); then
    endSkipping
  fi
}
