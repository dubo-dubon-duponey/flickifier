# for i in {$1..$2}; do
for ((i = $1; i <= $2; i += 1)); do
	data="$(./bin/flck-meta tt$(printf "%07d\n" $i))"

  jq <<<"$data"

	if [ ! "$(jq -rc .title <<<"$data")" ]; then
	  echo "No title"
	  exit 1
  fi

	if [ ! "$(jq -rc .original <<<"$data")" ]; then
	  echo "No original title"
	  exit 1
  fi

	if [ ! "$(jq -rc .director <<<"$data")" ] && [ ! "$(jq -rc .creator <<<"$data")" ]; then
	  echo "********** No director NOR creator **********"
	  echo "Waiting for order to continue"
	  read
  fi
  if [ "$(jq -rc .creator <<<"$data")" == "null" ]; then
    echo "null creator"
    exit 1
  fi

	if [ ! "$(jq -rc .duration <<<"$data")" ]; then
	  echo ">>>>>>>>>> No duration <<<<<<<<<<"
  fi

	if [ ! "$(jq -rc .year <<<"$data")" ]; then
	  echo "No year"
	  exit 1
  fi

	if [ ! "$(jq -rc .type <<<"$data")" ]; then
	  echo "No type"
	  exit 1
  fi

	if jq -rc .properties <<<"$data" | grep -q "|"; then
	  echo "Pipe in properties"
	  exit 1
  fi

done
