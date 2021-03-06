#!/bin/bash
# code copied from tomnomnom/gron (MIT license)

PROJDIR=$(cd `dirname $0` && pwd)

VERSION="${1}"
TAG="v${VERSION}"
USER="viktomas"
REPO="godu"
BINARY="${REPO}"

if [[ -z "${VERSION}" ]]; then
    echo "Usage: ${0} <version>"
    exit 1
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "You forgot to set your GITHUB_TOKEN"
    exit 2
fi

cd ${PROJDIR}

# Run the tests
go test
if [ $? -ne 0 ]; then
    echo "Tests failed. Aborting."
    exit 3
fi

# Check if tag exists
git fetch --tags
git tag | grep "^${TAG}$"

if [ $? -ne 0 ]; then
    # Install this binary here https://github.com/aktau/github-release#how-to-install
    github-release release \
        --user ${USER} \
        --repo ${REPO} \
        --tag ${TAG} \
        --name "${REPO} ${TAG}" \
        --description "${TAG}" \
        --pre-release
fi


ARCH="amd64"
for OS in "darwin" "linux" "windows"; do

    BINFILE="${BINARY}"

    if [[ "${OS}" == "windows" ]]; then
        BINFILE="${BINFILE}.exe"
    fi

    rm -f ${BINFILE}

    GOOS=${OS} GOARCH=${ARCH} go build -ldflags "-X main.goduVersion=${VERSION}" github.com/${USER}/${REPO}

    if [[ "${OS}" == "windows" ]]; then
        ARCHIVE="${BINARY}-${OS}-${ARCH}-${VERSION}.zip"
        zip ${ARCHIVE} ${BINFILE}
    else
        ARCHIVE="${BINARY}-${OS}-${ARCH}-${VERSION}.tgz"
        tar --create --gzip --file=${ARCHIVE} ${BINFILE}
    fi

    echo "Uploading ${ARCHIVE}..."
    github-release upload \
        --user ${USER} \
        --repo ${REPO} \
        --tag ${TAG} \
        --name "${ARCHIVE}" \
        --file ${PROJDIR}/${ARCHIVE}
done
