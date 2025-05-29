#!/usr/bin/env bash

set -euxo pipefail

COMPONENTS_DIR="content/en/flux/components"
FLUX_DIR="content/en/flux/cmd"

if [ -z "${GITHUB_USER:-}" ]; then
    GITHUB_USER=fluxcdbot
fi

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
    if [ -z "${OS:-}" ]; then
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
    if [ -z "${ARCH:-}" ]; then
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


gen_crd_doc() {
  URL="$1"
  DEST="$2"
  HUGETABLE="${3:-}"

  TMP="$(mktemp)"
  curl -u "$GITHUB_USER:$GITHUB_TOKEN" -# -Lf "$URL" > "$TMP"

  # Ok, so this section is not pretty, but we have a number of issues we need to look at here:
  #
  # 1. Some lines start with editor instructions (<!-- line length, blah something .. -->)
  # 2. Some title lines go <h1>Title is here</h1>
  # 3. While others go     # Here is the title you're looking for...
  #

  FIRST_LINE="$(grep -vEm1 "^<!--" "$TMP")"
  if echo "$FIRST_LINE" | grep -q "<h1>" ; then
    TITLE="$(echo "$FIRST_LINE" | cut -d'<' -f2 | cut -d'>' -f2 | sed 's/^\#\ //')"
  elif echo "$FIRST_LINE" | grep -E "^# "; then
    TITLE="$(echo "$FIRST_LINE" | sed 's/^\#\ //')"
  else
    echo "Don't know what to do with '$FIRST_LINE' in $TMP."
    exit 1
  fi

  WEIGHT="$(grep -E '^<!-- menuweight:[[:digit:]]+ -->$' "$TMP" | cut -d' ' -f2|cut -d':' -f2 || true)"
  if [ -z "${WEIGHT}" ] ; then
    WEIGHT=0
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
      echo "weight: $WEIGHT"
      echo "---"
    } >> "$DEST"
    grep -vE "^<!--" "$TMP" |sed '1d' >> "$DEST"
    rm "$TMP"
  else
    mv "$TMP" "$DEST"
  fi
}

function all_versions {
  for crd in $1 ; do
    echo "${crd##*,}"
  done | sort | uniq
}

function gen_ctrl_docs {
  flux_version=${1}
  ctrl=${2}
  ctrl_short=${ctrl%%-controller}
  ctrl_out=${ctrl%%-*} # this is necessary to collect IAC and IRC together in the "image" folder

  api_out="api"
  if [ "${ctrl_short}" = "image-reflector" ] ; then
    api_out="reflector-api"
  fi
  if [ "${ctrl_short}" = "image-automation" ] ; then
    api_out="automation-api"
  fi

  ks_url=$(curl -sL "https://raw.githubusercontent.com/fluxcd/flux2/${flux_version}/manifests/bases/${ctrl}/kustomization.yaml" | yq '.resources[]|select(. == "*crds.yaml*")')
  ctrl_version=$(echo "${ks_url}" | cut -d/ -f8)

  crds=$(curl -sL "${ks_url}" | yq ea '[[.metadata.name, .spec.versions[] | select(.storage == "true").name]]' -o csv)
  for api_version in $(all_versions "${crds}") ; do
    doc_url=https://raw.githubusercontent.com/fluxcd/${ctrl}/${ctrl_version}/docs/api/${api_version}/${ctrl_short}.md
    gen_crd_doc "${doc_url}" "$COMPONENTS_DIR/${ctrl_out}/${api_out}/${api_version}.md" "HUGETABLE"

  done

  for crd in ${crds} ; do
    name=${crd%%,*}
    name=${name%%.*}
    version=${crd##*,}
    gen_crd_doc "https://raw.githubusercontent.com/fluxcd/${ctrl}/${ctrl_version}/docs/spec/${version}/${name}.md" "$COMPONENTS_DIR/${ctrl_out}/${name}.md"
  done

  # special cases for n-c
  if [ "${ctrl}" = "notification-controller" ] ; then
    # `Events` type is not a CRD but needs to be documented, too.
    gen_crd_doc "https://raw.githubusercontent.com/fluxcd/${ctrl}/${ctrl_version}/docs/spec/v1beta2/events.md" "$COMPONENTS_DIR/${ctrl_out}/events.md"

    # Hack for fixing typo in the docs
    sed -i \
      's#((https://docs\.github\.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token))#(https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token)#g' \
      "$COMPONENTS_DIR/${ctrl_out}/providers.md"
    sed -i \
      's#((https://docs\.github\.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation))#(https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation)#g' \
      "$COMPONENTS_DIR/${ctrl_out}/providers.md"
  fi
}

{
  # get flux cmd docs
  setup_verify_os
  setup_verify_arch

  TMP="$(mktemp -d)"
  TMP_BIN="$TMP/flux.tar.gz"

  if [ -z "${BRANCH:-}" ] ; then
    fatal "BRANCH environment variable not set"
  fi

  if [[ "${BRANCH}" =~ ^pull/[[:digit:]]*/head$ ]] ; then
    BRANCH=$(curl -sSfL "https://api.github.com/repos/fluxcd/website/pulls/$(echo ${BRANCH}|cut -d/ -f2)" | jq .base.ref -r)
  fi

  VERSION_FLUX=
  for tag in $(curl -u "$GITHUB_USER:$GITHUB_TOKEN" --retry 3 -sSfL "https://api.github.com/repos/fluxcd/flux2/releases" | jq .[].tag_name -r) ; do
    if [ "${BRANCH}" = "main" ] ; then
      VERSION_FLUX="${tag#v}"
      break
    fi
    if [ "${tag%.*}" = "${BRANCH/-/.}" ] ; then
      VERSION_FLUX="${tag#v}"
      break
    fi
  done

  if [ -z "${VERSION_FLUX}" ] ; then
    fatal "No Flux version found matching branch '${BRANCH}'"
  fi

  curl -u "$GITHUB_USER:$GITHUB_TOKEN" -o "${TMP_BIN}" --retry 3 -sSfL "https://github.com/fluxcd/flux2/releases/download/v${VERSION_FLUX}/flux_${VERSION_FLUX}_${OS}_${ARCH}.tar.gz"
  tar xfz "${TMP_BIN}" -C "${TMP}"

  rm -rf "${FLUX_DIR:?}/*"
  "${TMP}/flux" docgen --path "${FLUX_DIR}"

  rm -rf "$TMP"
}

{
  # source-controller CRDs
  gen_ctrl_docs "v${VERSION_FLUX}" "source-controller"
}

{
  # kustomize-controller CRDs
  gen_ctrl_docs "v${VERSION_FLUX}" "kustomize-controller"
}

{
  # helm-controller CRDs
  gen_ctrl_docs "v${VERSION_FLUX}" "helm-controller"
}

{
  # notification-controller CRDs
  gen_ctrl_docs "v${VERSION_FLUX}" "notification-controller"
}

{
  # image-*-controller CRDs; these use the same API group
  gen_ctrl_docs "v${VERSION_FLUX}" "image-reflector-controller"
  gen_ctrl_docs "v${VERSION_FLUX}" "image-automation-controller"
}

{
  # provide Flux install script
  if [ ! -d static ]; then
    mkdir static
  fi
  curl -u "$GITHUB_USER:$GITHUB_TOKEN" -s -# -Lf "https://raw.githubusercontent.com/fluxcd/flux2/v${VERSION_FLUX}/install/flux.sh" -o static/install.sh
}

