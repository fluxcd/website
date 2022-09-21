#!/bin/sh

set -e

SCRIPT_NAME="./hack/update-helm-op.sh"

if [ ! -x "$SCRIPT_NAME" ]; then
    echo "Please run this script from top-level of the repository."
    exit 1
fi

HELM_OP_RELEASE_FILE=".helm-op-release"

if [ ! -f "$HELM_OP_RELEASE_FILE" ]; then
    echo "$HELM_OP_RELEASE_FILE does not exist."
    exit 1
fi

HELM_OP_RELEASE="$(cat $HELM_OP_RELEASE_FILE)"

if [ -z "$1" ]; then
    echo "Please pass new version as argument to the script, current version is: $HELM_OP_RELEASE."
    exit 1
fi

NEW_HELM_OP_RELEASE="$1"

HELM_OP_DOCS="content/en/legacy/helm-operator"

REGEX="$(echo $HELM_OP_RELEASE | sed 's/\./\\./g')"

find ${HELM_OP_DOCS} \
    -iname '*.md' \
    -type f \
    -exec sed -i "s/$REGEX/$NEW_HELM_OP_RELEASE/g" {} \;

echo "$NEW_HELM_OP_RELEASE" > $HELM_OP_RELEASE_FILE
