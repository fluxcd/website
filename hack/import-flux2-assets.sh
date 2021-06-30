#!/bin/sh

COMPONENTS_DIR="content/en/docs/components"
FLUX_DIR="content/en/docs/cmd"

if [ ! "$(command -v jq)" ]; then
  echo "Please install 'jq'."
  exit 1
fi

fatal() {
    echo '[ERROR] ' "$@" >&2
    exit 1
}

# Set os, fatal if operating system not supported
setup_verify_os() {
    if [ -z "${OS}" ]; then
        OS=$(uname)
    fi
    case ${OS} in
        Darwin)
            OS=darwin
            ;;
        Linux)
            OS=linux
            ;;
        *)
            fatal "Unsupported operating system ${OS}"
    esac
}

# Set arch, fatal if architecture not supported
setup_verify_arch() {
    if [ -z "${ARCH}" ]; then
        ARCH=$(uname -m)
    fi
    case ${ARCH} in
        arm|armv6l|armv7l)
            ARCH=arm
            ;;
        arm64|aarch64|armv8l)
            ARCH=arm64
            ;;
        amd64)
            ARCH=amd64
            ;;
        x86_64)
            ARCH=amd64
            ;;
        *)
            fatal "Unsupported architecture ${ARCH}"
    esac
}


controller_version() {
  curl -s "https://api.github.com/repos/fluxcd/$1/releases" | jq -r '.[] | .tag_name' | sort -V | tail -n 1
}

gen_crd_doc() {
  URL="$1"
  DEST="$2"
  HUGETABLE="$3"

  TMP="$(mktemp)"
  curl -# -Lf "$URL" > "$TMP"

  # Ok, so this section is not pretty, but we have a number of issues we need to look at here:
  #
  # 1. Some lines start with editor instructions (<!-- line length, blah something .. -->)
  # 2. Some title lines go <h1>Title is here</h1>
  # 3. While others go     # Here is the title you're looking for...
  #

  FIRST_LINE="$(grep -vE "^<!--" "$TMP" | head -n1)"
  if echo "$FIRST_LINE" | grep -q "<h1>" ; then
    TITLE="$(echo "$FIRST_LINE" | cut -d'<' -f2 | cut -d'>' -f2 | sed 's/^\#\ //')"
  elif echo "$FIRST_LINE" | grep -E "^# "; then
    TITLE="$(echo "$FIRST_LINE" | sed 's/^\#\ //')"
  else
    echo "Don't know what to do with '$FIRST_LINE' in $TMP."
    exit 1
  fi

  if [ -n "$TITLE" ]; then
    {
      echo "---"
      echo "title: $TITLE"
      echo "description: The GitOps Toolkit Custom Resource Definitions documentation."
      echo "importedDoc: true"
      if [ -n "$HUGETABLE" ]; then
        echo "hugeTable: true"
      fi
      echo "---"
    } >> "$DEST"
    grep -vE "^<!--" "$TMP" |sed '1d' >> "$DEST"
    rm "$TMP"
  else
    mv "$TMP" "$DEST"
  fi
}

{
  # source-controller CRDs
  SOURCE_VER="$(controller_version source-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/api/source.md" "$COMPONENTS_DIR/source/api.md" "HUGETABLE"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/spec/v1beta1/gitrepositories.md" "$COMPONENTS_DIR/source/gitrepositories.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/spec/v1beta1/helmrepositories.md" "$COMPONENTS_DIR/source/helmrepositories.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/spec/v1beta1/helmcharts.md" "$COMPONENTS_DIR/source/helmcharts.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/spec/v1beta1/buckets.md" "$COMPONENTS_DIR/source/buckets.md"
}

{
  # kustomize-controller CRDs
  KUSTOMIZE_VER="$(controller_version kustomize-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/kustomize-controller/$KUSTOMIZE_VER/docs/api/kustomize.md" "$COMPONENTS_DIR/kustomize/api.md" "HUGETABLE"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/kustomize-controller/$KUSTOMIZE_VER/docs/spec/v1beta1/kustomization.md" "$COMPONENTS_DIR/kustomize/kustomization.md"
}

{
  # helm-controller CRDs
  HELM_VER="$(controller_version helm-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/helm-controller/$HELM_VER/docs/api/helmrelease.md" "$COMPONENTS_DIR/helm/api.md" "HUGETABLE"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/helm-controller/$HELM_VER/docs/spec/v2beta1/helmreleases.md" "$COMPONENTS_DIR/helm/helmreleases.md"
}

{
  # notification-controller CRDs
  NOTIFICATION_VER="$(controller_version notification-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/notification-controller/$NOTIFICATION_VER/docs/api/notification.md" "$COMPONENTS_DIR/notification/api.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/notification-controller/$NOTIFICATION_VER/docs/spec/v1beta1/event.md" "$COMPONENTS_DIR/notification/event.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/notification-controller/$NOTIFICATION_VER/docs/spec/v1beta1/alert.md" "$COMPONENTS_DIR/notification/alert.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/notification-controller/$NOTIFICATION_VER/docs/spec/v1beta1/provider.md" "$COMPONENTS_DIR/notification/provider.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/notification-controller/$NOTIFICATION_VER/docs/spec/v1beta1/receiver.md" "$COMPONENTS_DIR/notification/receiver.md"
}

{
  # image-*-controller CRDs; these use the same API group
  IMG_REFL_VER="$(controller_version image-reflector-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-reflector-controller/$IMG_REFL_VER/docs/api/image-reflector.md" "$COMPONENTS_DIR/image/reflector-api.md" "HUGETABLE"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-reflector-controller/$IMG_REFL_VER/docs/spec/v1beta1/imagerepositories.md" "$COMPONENTS_DIR/image/imagerepositories.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-reflector-controller/$IMG_REFL_VER/docs/spec/v1beta1/imagepolicies.md" "$COMPONENTS_DIR/image/imagepolicies.md"

  IMG_AUTO_VER="$(controller_version image-automation-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-automation-controller/$IMG_AUTO_VER/docs/api/image-automation.md" "$COMPONENTS_DIR/image/automation-api.md" "HUGETABLE"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-automation-controller/$IMG_AUTO_VER/docs/spec/v1beta1/imageupdateautomations.md" "$COMPONENTS_DIR/image/imageupdateautomations.md"
}

{
  # get flux cmd docs
  setup_verify_os
  setup_verify_arch

  TMP="$(mktemp -d)"
  TMP_METADATA="$TMP/flux.json"
  TMP_BIN="$TMP/flux.tar.gz"

  curl -o "${TMP_METADATA}" -sfL "https://api.github.com/repos/fluxcd/flux2/releases/latest"
  VERSION_FLUX=$(grep '"tag_name":' "${TMP_METADATA}" | sed -E 's/.*"([^"]+)".*/\1/' | cut -c 2-)

  curl -o "${TMP_BIN}" -sfL "https://github.com/fluxcd/flux2/releases/download/v${VERSION_FLUX}/flux_${VERSION_FLUX}_${OS}_${ARCH}.tar.gz"
  tar xfz "${TMP_BIN}" -C "${TMP}"

  rm -rf "${FLUX_DIR:?}/*"
  "${TMP}/flux" docgen --path "${FLUX_DIR}"

  rm -rf "$TMP"
}

{
  # provide Flux install script
  if [ ! -d static ]; then
    mkdir static
  fi
  curl -s -# -Lf https://raw.githubusercontent.com/fluxcd/flux2/main/install/flux.sh -o static/install.sh
}

