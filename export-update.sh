#!/usr/bin/env bash
# set -xv

APP_DIR=$(pwd)
IMPORT_DIR=${IMPORT_DIR:-/import}
TILES_DIR=${TILES_DIR:-${IMPORT_DIR}}
cd ${TILES_DIR}

function finish () {
  status=$?
  echo "Couaght a signal: $status. Exiting."
  exit $status
}
trap finish TERM HUP INT TSTP PIPE QUIT EXIT

function show_progress() {
  # DEBUG # echo Refreshing $tiles_file list ...
  let now=$(date +%s)
  let created=$(date --utc -d "${tiles_file:0:8} ${tiles_file:9:2}:${tiles_file:11:2}:${tiles_file:13:2}" +%s)
  let diff="$now - $created"
  # TODO echo gap of more than 24 hours
  echo "[$(date -d "@$now")]" Refreshing tiles updated on $(date -d "@$created"), $(date -d "@$diff" --utc +%R:%S) hours ago
  sleep 2 || exit $?
}

sleeping=0
while true ; do 
  for tiles_file in */*.tiles; do
    if [[ ${tiles_file} != "*/*.tiles" ]] ; then
      # A tiles file was found
      [[ $sleeping == 0 ]] || echo "" >&2
      sleeping=0
      show_progress
      cp $tiles_file ${IMPORT_DIR}/tiles.txt
      retry=0
      while ! ( cd ${APP_DIR}; 
	    # Filter-out the "is deprecated" warnings from stderr
	    EXPORT_DIR=${IMPORT_DIR} ./export-list.sh 3>&2 2> >(sed '/is deprecated/d' >&3)
	  ) ; do
	let retry+=1
	echo Refresh returned an error. Retry "#${retry}..."
	sleep 15 || exit $?
      done
      rm $tiles_file ${IMPORT_DIR}/tiles.txt
    else
      [[ $sleeping == 1 ]] || echo -n Sleeping.. >&2
      sleeping=1
      echo -n . >&2
      sleep 15 || exit $?
    fi
  done
done
