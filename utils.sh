#!/bin/bash
set -o errexit
set -o pipefail

readonly DEST_PROJECT_DIR="/tmp/project"
readonly DEST_PROJECT_FILE="${DEST_PROJECT_DIR%%/}/data.yml"

# project config will be copied to new folder because we
# modify the source configuration
function copy_source_project() {
    cp -rf "$SOURCE_PROJECT_DIR" "$DEST_PROJECT_DIR"
}

# project.yml is single source of truth, therefore the mapnik
# stylesheet is not necessary
function cleanup_dest_project() {
    rm -f "${DEST_PROJECT_DIR%%/}/project.xml"
}

# replace database connection with postgis container connection
function replace_db_connection() {
    local replace_expr_1="s|host: .*|host: \"$POSTGRES_HOST\"|g"
    local replace_expr_2="s|port: .*|port: \"$POSTGRES_PORT\"|g"
    local replace_expr_3="s|dbname: .*|dbname: \"$POSTGRES_DB\"|g"
    local replace_expr_4="s|user: .*|user: \"$POSTGRES_USER\"|g"
    local replace_expr_5="s|password: .*|password: \"$POSTGRES_PASSWORD\"|g"

    sed -i "$replace_expr_1" "$DEST_PROJECT_FILE"
    sed -i "$replace_expr_2" "$DEST_PROJECT_FILE"
    sed -i "$replace_expr_3" "$DEST_PROJECT_FILE"
    sed -i "$replace_expr_4" "$DEST_PROJECT_FILE"
    sed -i "$replace_expr_5" "$DEST_PROJECT_FILE"
}

# Fix Mapnik output and errors
#
# Usage:
#   filter_deprecation tilelive-copy ...
#
function filter_deprecation()(
  (
    # Swap stdin and stderr
    "$@" 3>&2- 2>&1- 1>&3- | (
      # Remove "is deprecated" error messages
      sed -u "/is deprecated/d"
  # Swap back stdin and stderr
  )) 3>&2- 2>&1- 1>&3- | \
  # Fix time precision
  sed -u "s/s\] /000&/;s/\(\.[0-9][0-9][0-9]\)[0-9]*s\] /\1s] /" | \
  # Redraw progress on the same line
  while read line; do
  if [[ "$line" == *left ]] ; then
    echo -n "$line"
  else
    echo "$line"
  fi
done
);
