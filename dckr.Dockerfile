##################################################################
FROM com.dbdbdp.dckr:alpine-current as alpine-current
# no shellcheck package on alpine
RUN apk add --no-cache make git bash ncurses grep gnupg
RUN apk add --no-cache curl jq sqlite
RUN apk add --no-cache file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr

##################################################################
FROM com.dbdbdp.dckr:alpine-current as alpine-next
# no shellcheck package on alpine
RUN apk add --no-cache make git bash ncurses grep gnupg
RUN apk add --no-cache curl jq sqlite
RUN apk add --no-cache file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr

##################################################################
FROM com.dbdbdp.dckr:ubuntu-lts-old as ubuntu-lts-old
RUN apt-get install -y --no-install-recommends make git shellcheck ca-certificates
RUN apt-get install -y --no-install-recommends curl jq sqlite3
RUN apt-get install -y --no-install-recommends file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr

##################################################################
FROM com.dbdbdp.dckr:ubuntu-lts-current as ubuntu-lts-current
RUN apt-get install -y --no-install-recommends make git shellcheck gpg ca-certificates
RUN apt-get install -y --no-install-recommends curl jq sqlite3
RUN apt-get install -y --no-install-recommends file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr

##################################################################
FROM com.dbdbdp.dckr:ubuntu-current as ubuntu-current
RUN apt-get install -y --no-install-recommends make git shellcheck gpg ca-certificates
RUN apt-get install -y --no-install-recommends curl jq sqlite3
RUN apt-get install -y --no-install-recommends file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr

##################################################################
FROM com.dbdbdp.dckr:ubuntu-next as ubuntu-next
RUN apt-get install -y --no-install-recommends make git shellcheck gpg ca-certificates
RUN apt-get install -y --no-install-recommends curl jq sqlite3
RUN apt-get install -y --no-install-recommends file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr

##################################################################
FROM com.dbdbdp.dckr:debian-old as debian-old
RUN apt-get install -y --no-install-recommends make git shellcheck gpg ca-certificates
RUN apt-get install -y --no-install-recommends curl jq sqlite3
RUN apt-get install -y --no-install-recommends file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr

##################################################################
FROM com.dbdbdp.dckr:debian-current as debian-current
RUN apt-get install -y --no-install-recommends make git shellcheck gpg ca-certificates
RUN apt-get install -y --no-install-recommends curl jq sqlite3
RUN apt-get install -y --no-install-recommends file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr

##################################################################
FROM com.dbdbdp.dckr:debian-next as debian-next
RUN apt-get install -y --no-install-recommends make git shellcheck gpg ca-certificates
RUN apt-get install -y --no-install-recommends curl jq sqlite3
RUN apt-get install -y --no-install-recommends file ffmpeg # bento4
ENV DC_PREFIX=/tmp
USER dckr
