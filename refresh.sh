
# XXX redo lowdef later after dedup
# candidate="$(jq -rc 'select(.category == "207") | select(.seeders | tonumber > 40)' < torrent-for-lowdef-replace.txt)"

# Done with this
if [ "$3" ]; then
  candidate="$(jq -rc 'select(.category == "207") | select((.seeders | tonumber > 0)) | select((.seeders | tonumber > '"$2"') or (.leechers | tonumber > '"$2"'))' < "$1")"
else
  candidate="$(jq -rc 'select((.seeders | tonumber > '"$2"') or (.leechers | tonumber > '"$2"'))' < "$1")"
fi
notdead="$(jq -rc 'select((.seeders | tonumber > 0))' < "$1")"
hdnotdead="$(jq -rc 'select(.category == "207") | select((.seeders | tonumber > 0))' < "$1")"
# candidate="$(jq -rc 'select(.category == "207") | select(.seeders | tonumber > 2)' < torrent-for-dvd-replace-2.txt)"

list="$(jq -rc '.hash + "|" + .imdb + "|" + .magnet' <<<"$candidate")"

echo " >>>>> Auditing $1 - minimum number of seeders or leechers: $2 - restricting to highdef? ($3)"
echo "selected: $(wc -l <<<"$list") / HD not dead: $(wc -l <<<"$hdnotdead") / not dead: $(wc -l <<<"$notdead") / total: $(wc -l <"$1")"

for i in $list; do
  hash=${i%|*}
  imdb=${hash##*|}
  hash=${hash%|*}
  mag=${i##*|}

  mkdir -p "$HOME/Downloads/Transmission/Intorrent/$imdb"
  if [ ! -f "$HOME/Downloads/Transmission/Intorrent/$imdb/$hash.torrent" ]; then
    echo "Fetching $imdb ($hash)"
    aria2c --bt-metadata-only=true --bt-save-metadata=true -d "$HOME/Downloads/Transmission/Intorrent/$imdb" -q "$mag"
  fi
#  open "$HOME/Downloads/Transmission/Intorrent/$imdb/$hash.torrent"
done

exit

while read -r line; do
#  jq . <<<"$line"
  echo "Do you want to download this ^?"
#  read -r -t 10 confirm
#  if [ "$confirm" != "y" ]; then
#    continue
#  fi
done <<<"$candidate"


# te generate a refresher file: make build; for i in /Volumes/OnePotato/The\ End\ of\ Silence/x.\ the\ rest/*; do id="$(basename "$i" | perl -pe "s/.*(tt[0-9]+).*/\1/")"; FI_SUCKER_LOG_LEVEL=info ./bin/fi-sucker --min-seeders=0 --limit=20 "$id"; done > torrent-for-lowdef-replace.txt


# to get all movies from a director:
# name="Alfred Hitchcok"; while read -r id; do FI_SUCKER_LOG_LEVEL=info ./bin/fi-sucker --min-seeders=0 --limit=20 "$id"; done < <(./bin/flck-meta "$(./bin/flck-meta --type=person "$name" | jq -rc .[0].id)" | jq -rc '.movies.director[].id') > "torrent-$name.txt"

# while read -r id; do FI_SUCKER_LOG_LEVEL=info ./bin/fi-sucker --min-seeders=0 --limit=20 "$id"; done < <(./bin/flck-meta nm0895048 | jq -rc '.movies.director[].id') > torrent.txt
# then to get going
# ./refresh.sh torrent.txt 5 hidefonly
# ./refresh.sh torrent.txt 5
