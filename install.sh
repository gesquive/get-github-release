#!/usr/bin/env bash
# install get-github-release
set -e

DL_URL="https://raw.githubusercontent.com/gesquive/get-github-release/master/get-github-release.sh"
OUTPATH="/usr/local/bin/get-github-release"

if [ "$1" == "local" ]; then # local install
    cp get-github-release.sh "${OUTPATH}"
else # internet install
    curl -sfL ${DL_URL} -o "${OUTPATH}"
fi

chmod +x "${OUTPATH}"
