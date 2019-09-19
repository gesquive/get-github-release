#!/usr/bin/env bash
# get-github-release
# https://github.com/gesquive/get-github-release

shopt -s nocasematch

VERSION="v1.0.0"
VERBOSE=true
DEST="."
RELEASE_TAG="latest"

CURL=${CURL:-curl}
MKTMP=${MKTMP:-mktemp}
TR=${TR:-tr}

function usage() {
    echo "Utility script to download a github release from a public github repo"
    echo ""
    echo "Usage:"
    echo "  get-github-release [flags] <REPO>"
    echo ""
    echo "Flags:"
    echo "  -q, --quiet     Silence all output"
    echo "  -d, --dest      The destination path & name (default:PWD)"
    echo "  -t, --tag       The tag name to download (default:latest)"
    echo "  -e, --extract   The file to extract and save, this must match the name in the archive"
    echo "  -h, --help      Show this help and exit"
    echo "  --version       Show the version and exit"
    exit 1;
}

function version() {
    echo "get_github_release ${VERSION}"
    exit 1
}

while getopts 'vq:d:t:e:h-' OPTION ; do
  case "$OPTION" in
    v  ) VERBOSE=true                   ;;
    q  ) VERBOSE=false                  ;;
    d  ) DEST="${OPTARG}"               ;;
    t  ) RELEASE_TAG="${OPTARG}"        ;;
    e  ) EXTRACT="${OPTARG}"            ;;
    h  ) usage                          ;;
    -  ) [ $OPTIND -ge 1 ] && optind=$(expr $OPTIND - 1 ) || optind=$OPTIND
         eval OPTION="\$$optind"
         OPTARG=$(echo $OPTION | cut -d'=' -f2)
         OPTION=$(echo $OPTION | cut -d'=' -f1)
         case $OPTION in
             --verbose   ) VERBOSE=true             ;;
             --quiet     ) VERBOSE=false            ;;
             --dest      ) DEST="${OPTARG}"         ;;
             --tag       ) RELEASE_TAG="${OPTARG}"  ;;
             --extract   ) EXTRACT="${OPTARG}"      ;;
             --help      ) usage                    ;;
             --version   ) version                  ;;
             * )  usage                             ;;
         esac
       OPTIND=1
       shift
      ;;
    ? )  usage                          ;;
  esac
done
if [ $(( $# - $OPTIND )) -lt 0 ]; then
    usage
    exit 1
fi

# positional repo argument
REPO=${*:$OPTIND:1}

function print() {
    if ${VERBOSE}; then
        printf "$*\n"
    fi
}

function perr() {
    printf "$*\n" >&2
}
function check() {
    if ! type "$1" &> /dev/null; then
        return 1;
    fi
    return 0
}
function check_fatal() {
    if ! check $1; then
        perr "$1 not found! Make sure it is installed."
        exit 2
    fi
}

check_fatal ${CURL}
check_fatal ${MKTMP}
check_fatal ${TR}

LATEST_URL="https://api.github.com/repos/${REPO}/releases/${RELEASE_TAG}"

# First, query github for the latest release info
RELEASES=$(${CURL} -sfL ${LATEST_URL})
# check if we got back a 404
RELEASE_STATUS="$?"
if  [ ! ${RELEASE_STATUS} -eq 0 ]; then
    perr "Could not locate releases for '${REPO}:${RELEASE_TAG}', make sure it exists"
    print ${LATEST_URL}
    exit 1
fi

OS=$(uname -s)
ARCH=$(uname -m)

OS_DARWIN_RE="darwin|osx|mac"
OS_LINUX_RE="linux"

ARCH_64_RE="amd64|x64|x86_64"
ARCH_32_RE="i?386|x32|i?686"

if [[ $OS =~ $OS_LINUX_RE ]]; then
    OS_RE=$OS_LINUX_RE
elif [[ $OS =~ $OS_DARWIN_RE ]]; then
    OS_RE=$OS_DARWIN_RE
fi

if [[ $ARCH =~ $ARCH_64_RE ]]; then
    ARCH_RE=$ARCH_64_RE
elif [[ $ARCH =~ $ARCH_32_RE ]]; then
    ARCH_RE=$ARCH_32_RE
fi

SEARCH_RE=".*(${OS_RE}).*(${ARCH_RE}).*"

DOWNLOAD_URL=$(echo "${RELEASES}" | grep "browser_download_url" | grep -iE "${SEARCH_RE}" | cut -d '"' -f 4)

# check if any url was found or if more then one was found
DL_URL_COUNT=$(printf "%s" "${DOWNLOAD_URL}" | grep -c "^")
if [ ${DL_URL_COUNT} -eq 0 ]; then
    perr "No matching releases were found"
    exit 2
elif [ ${DL_URL_COUNT} -gt 1 ]; then
    perr "Too many matching releases"
    exit 3
fi

print "Found ${DL_URL_COUNT} matching download(s) at ${DOWNLOAD_URL}"

if [ ! -z "${EXTRACT}" ]; then
    TMP=$(${MKTMP} -d)
    ARCHIVE="${DOWNLOAD_URL##*/}"
    WKDIR=${PWD}
    cd "${TMP}"
    ${CURL} -O -L ${DOWNLOAD_URL}
    DL_STATUS="$?"
    if  [ ! ${DL_STATUS} -eq 0 ]; then
        perr "Failed to download package from '${DOWNLOAD_URL}'."
        exit 10
    fi
    NAME=$(echo "${ARCHIVE}" | ${TR} '[:upper:]' '[:lower:]')
    case "${NAME}" in
        *.tar.bz)   tar -xjf "${ARCHIVE}" "${EXTRACT}" ;;
        *.tar.bz2)  tar -xjf "${ARCHIVE}" "${EXTRACT}" ;;
        *.tar.gz)   tar -xzf "${ARCHIVE}" "${EXTRACT}" ;;
        *.tar.xz)   tar -xJf "${ARCHIVE}" "${EXTRACT}" ;;
        *.lzma)     xz -dfk "${ARCHIVE}" "${EXTRACT}" ;;
        *.pxz)      xz -dfk "${ARCHIVE}" "${EXTRACT}" ;;
        *.tar)      tar -xf "${ARCHIVE}" "${EXTRACT}" ;;
        *.tbz)      tar -xjf "${ARCHIVE}" "${EXTRACT}" ;;
        *.tbz2)     tar -xjf "${ARCHIVE}" "${EXTRACT}" ;;
        *.tz2)      tar -xjf "${ARCHIVE}" "${EXTRACT}" ;;
        *.tgz)      tar -xzf "${ARCHIVE}" "${EXTRACT}" ;;
        *.txz)      tar -xJf "${ARCHIVE}" "${EXTRACT}" ;;
        *.xz)       xz -dfk "${ARCHIVE}" "${EXTRACT}" ;;
        *.zip)      unzip -p "${ARCHIVE}" "${EXTRACT}" >"${EXTRACT##*/}" ;;
        *.7z)       7z x "${ARCHIVE}" "${EXTRACT}" ;;
        *) perr "extract: '${ARCHIVE}' - unknown archive method" ;;
    esac
    cd ${WKDIR}
    mv "${TMP}/${EXTRACT}" "${DEST}"
    rm -rf "${TMP}"
    exit

else # download the archive
    OUTARG=""
    if [ ! -z "${DEST}" ]; then
        OUTARG=" -o ${DEST}"
    fi
    if [ -d "${DEST}" ]; then
        OUTARG=" -O ${OUTARG}"
    fi
    print "Saving archive to '${DEST}'"
    ${CURL}${OUTARG} -L ${DOWNLOAD_URL}

    DL_STATUS="$?"
    if  [ ! ${DL_STATUS} -eq 0 ]; then
        perr "Failed to download package from '${DOWNLOAD_URL}'."
        exit 10
    fi
fi


