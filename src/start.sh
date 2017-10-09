#!/bin/bash

if [ -z "${1:-}" -o -z "${2:-}" ]; then
	echo "Missing parameters";
	exit;
else
	NAME="$1";
	SOURCE="$2";
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

cat "${CONFIG}" | sed "s/\[SOURCE\]/${SOURCE//\//\\/}/" | sed "s/\[NAME\]/${NAME}/" > "${ROOT}/.Rconfig";

mate /Volumes/WebServer/Projects/craig.rstats/
mate /Volumes/WebServer/Projects/craig.rstats/notes.txt

/Applications/R.app/Contents/MacOS/R "${ROOT}/" --arg ${NAME} &
