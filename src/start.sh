#!/bin/bash

if [ -z "${1:-}" -o -z "${2:-}" ]; then
	echo "Missing parameters";
	exit;
else
	NAME="$1";
	SRC_DETAIL="$2";
	SRC_ERRORS="$3";
fi

ROOT="/Volumes/WebServer/Projects/craig.rstats/src";

cd "${ROOT}";

if [ -f "${ROOT}/.RData" ]; then
	rm "${ROOT}/.RData";
fi

if [ -L "${ROOT}/.Rconfig" ]; then
	rm "${ROOT}/.Rconfig";
fi

CONFIG="/Volumes/WebServer/Projects/${NAME}/stats/config.r";
if [ ! -f "$CONFIG" ]; then
	echo "Missing config: $CONFIG";
	exit;
fi

cat "${CONFIG}" | sed "s/\[SRC_DETAIL\]/${SRC_DETAIL//\//\\/}/" | sed "s/\[SRC_ERRORS\]/${SRC_ERRORS//\//\\/}/" | sed "s/\[NAME\]/${NAME}/" > "${ROOT}/.Rconfig";

if [ -n "${4:-}" ]; then

	echo "" >> "${ROOT}/.Rconfig";
	echo "auto_save_stats_ip = '${4:-}';" >> "${ROOT}/.Rconfig";

	/Applications/R.app/Contents/MacOS/R "${ROOT}/"

else

	mate /Volumes/WebServer/Projects/craig.rstats/
	mate /Volumes/WebServer/Projects/craig.rstats/notes.txt

	/Applications/R.app/Contents/MacOS/R "${ROOT}/" &

fi
