UNDOCUMENTED

MOSTLY EXPERIMENTAL RIGHT NOW


# Take a directory and normalize folders and file names:
make; PATH=$(pwd)/bin:$PATH find /Users/dmp/Movies/Nou -type d -mindepth 1 -exec fi-teos-rehash {} \;

# Add nfo files for plex
find /Users/dmp/Movies/Nou -type d -mindepth 1 -maxdepth 1 -exec ./replex.sh {} \;

