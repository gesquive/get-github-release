#!/usr/bin/env bash
# install get-github-release
set -e

DL_URL="https://raw.githubusercontent.com/gesquive/get-github-release/master/get-github-release.sh"
OUTPATH="/usr/local/bin/get-github-release"

curl -o ${OUTPATH} -sfL ${DL_URL}
chmod +x ${OUTPATH}
