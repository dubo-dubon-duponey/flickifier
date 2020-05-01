#!/usr/bin/env bash

echo "--------------------------------------"
directory="/Volumes/OnePotato/The End of Silence"
echo "To be renamed"
find "$directory" -type d -mindepth 1 -maxdepth 1 -iname "to be renamed"

echo "--------------------------------------"
directory="/Volumes/OnePotato/The End of Silence/0. h264+ ultra High Res"
echo "NOT u-HD"
./filter-hd.sh "$directory" not-uhd

echo "--------------------------------------"
directory="/Volumes/OnePotato/The End of Silence/1. h264+ High Res"
echo "NOT HD"
./filter-hd.sh "$directory" not-hd

echo "--------------------------------------"
directory="/Volumes/OnePotato/The End of Silence/2. h264+ DVD"
echo "NOT h264+ DVD"
./filter-hd.sh "$directory" not-hmd

echo "--------------------------------------"
directory="/Volumes/OnePotato/The End of Silence/3. mpeg4 DVD"
echo "NOT mpeg4 DVD"
./filter-hd.sh "$directory" not-mmd

echo "--------------------------------------"
directory="/Volumes/OnePotato/The End of Silence/x. the rest"
echo "NOT LD"
./filter-hd.sh "$directory" not-ld

echo "--------------------------------------"
directory="/Volumes/OnePotato/The End of Silence/0. h264+ ultra High Res"
echo "KO files (uhd)"
find "$directory" -type d -mindepth 1 -maxdepth 1 -name "* KO*"

directory="/Volumes/OnePotato/The End of Silence/1. h264+ High Res"
echo "KO files (hd)"
find "$directory" -type d -mindepth 1 -maxdepth 1 -iname "* KO*"

echo "--------------------------------------"
echo "Duplicates"
# ./dupe.sh > list.txt; cat list.txt | sort | uniq -d
