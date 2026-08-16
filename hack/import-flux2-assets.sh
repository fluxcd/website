#!/usr/bin/env bash

set -euxo pipefail

COMPONENTS_DIR="content/en/flux/components"
FLUX_DIR="content/en/flux/cmd"
FLUX_PLUGIN_DIR="content/en/flux/cli-plugins"

if [ -z "${GITHUB_USER:-}" ]; then
    GITHUB_USER=fluxcdbot
fi

if [ "$(command -v gsed)" ]; then
  SED=$(which gsed)
else
  SED=$(which sed)
fi

if [ ! "$(command -v jq)" ]; then
  echo "Please install 'jq'."
  exit 1
fi

fatal() {
    echo '[ERROR] ' "$@" >&2
    exit 1
}

yaml_escape() {
  printf '%s' "$1" | $SED "s/'/''/g"
}

title_from_slug() {
  echo "$1" | tr '_-' '  ' | awk '{
    for (i = 1; i <= NF; i++) {
      $i = toupper(substr($i, 1, 1)) substr($i, 2)
    }
    print
  }'
}

extract_markdown_title() {
  local file="$1"
  local first_line

  first_line="$(grep -vEm1 "^<!--" "$file" || true)"
  if echo "$first_line" | grep -q "<h1>" ; then
    echo "$first_line" | cut -d'<' -f2 | cut -d'>' -f2 | $SED 's/^\#\ //'
  elif echo "$first_line" | grep -E "^# " >/dev/null; then
    echo "$first_line" | $SED 's/^\#\ //'
  fi
}

write_plugin_front_matter() {
  local dest="$1"
  local title="$2"
  local link_title="$3"
  local weight="$4"

  {
    echo "---"
    echo "title: '$(yaml_escape "$title")'"
    if [ -n "$link_title" ]; then
      echo "linkTitle: '$(yaml_escape "$link_title")'"
    fi
    echo "description: \"Official Flux CLI plugin documentation.\""
    echo "importedDoc: true"
    if [ -n "$weight" ]; then
      echo "weight: $weight"
    fi
    echo "---"
    echo
  } > "$dest"
}

write_plugin_section_index() {
  local dest="$1"
  local title="$2"
  local link_title="$3"
  local weight="$4"
  local body="$5"

  mkdir -p "$(dirname "$dest")"
  write_plugin_front_matter "$dest" "$title" "$link_title" "$weight"
  echo "$body" >> "$dest"
}

urlencode_ref() {
  echo "${1//\//%2F}"
}

github_contents() {
  local repo="$1"
  local ref="$2"
  local path="$3"
  local dest="$4"
  local encoded_ref

  encoded_ref="$(urlencode_ref "$ref")"
  curl -u "$GITHUB_USER:$GITHUB_TOKEN" --retry 3 -sSfL \
    "https://api.github.com/repos/fluxcd/${repo}/contents/${path}?ref=${encoded_ref}" \
    -o "$dest"
}

github_download_url() {
  local repo="$1"
  local ref="$2"
  local path="$3"
  local tmp

  tmp="$(mktemp)"
  github_contents "$repo" "$ref" "$path" "$tmp"
  jq -r '.download_url' "$tmp"
  rm -f "$tmp"
}

github_latest_release_tag() {
  local repo="$1"
  local tmp
  local tag

  tmp="$(mktemp)"
  if ! curl -u "$GITHUB_USER:$GITHUB_TOKEN" --retry 3 -sSfL \
    "https://api.github.com/repos/fluxcd/${repo}/releases/latest" \
    -o "$tmp"; then
    rm -f "$tmp"
    fatal "Unable to determine latest release tag for fluxcd/${repo}"
  fi

  tag="$(jq -r '.tag_name // empty' "$tmp")"
  rm -f "$tmp"

  if [ -z "$tag" ]; then
    fatal "Latest release tag for fluxcd/${repo} is empty"
  fi

  echo "$tag"
}

rewrite_plugin_links() {
  local dest="$1"
  local repo="$2"
  local ref="$3"
  local source_path="$4"

  python3 - "$dest" "$repo" "$ref" "$source_path" <<'PY'
import posixpath
import re
import sys
from pathlib import Path

path, repo, ref, source_path = sys.argv[1:5]
source_dir = posixpath.dirname(source_path)
github_base = f'https://github.com/fluxcd/{repo}'


def rewrite(match):
    url = match.group(1)
    if url.startswith(('http://', 'https://', 'mailto:', '#', '/', '{{')):
        return match.group(0)

    link_path, separator, fragment = url.partition('#')
    if not link_path:
        return match.group(0)

    source_target = posixpath.normpath(posixpath.join(source_dir, link_path))
    fragment = f'#{fragment}' if separator else ''
    if not source_target.startswith('docs/'):
        kind = 'tree' if link_path.endswith('/') or not posixpath.splitext(source_target)[1] else 'blob'
        return f']({github_base}/{kind}/{ref}/{source_target}{fragment})'

    if posixpath.splitext(source_target)[1] and not source_target.endswith('.md'):
        return f']({github_base}/blob/{ref}/{source_target}{fragment})'

    if not source_path.startswith('docs/'):
        website_path = source_target[len('docs/'):]
    else:
        website_path = link_path
    website_path = re.sub(r'(^|/)README\.md$', r'\1index.md', website_path)
    return f']({website_path}{fragment})'

content = Path(path).read_text()
content = re.sub(r'\]\(([^)\s]+)\)', rewrite, content)
Path(path).write_text(content)
PY
}


gen_plugin_readme_index() {
  local url="$1"
  local dest="$2"
  local title="$3"
  local weight="$4"
  local repo="$5"
  local ref="$6"
  local source_path="$7"
  local tmp

  tmp="$(mktemp)"
  mkdir -p "$(dirname "$dest")"
  curl -u "$GITHUB_USER:$GITHUB_TOKEN" -# -Lf "$url" > "$tmp"

  write_plugin_front_matter "$dest" "$title" "$title" "$weight"
  python3 - "$tmp" >> "$dest" <<'PY_README'
import sys
from pathlib import Path

lines = Path(sys.argv[1]).read_text().splitlines()
out = []
skipped_heading = False
started = False
started_selected_section = False
selected_sections = {'## Features', '## Install', '## Quickstart'}

for line in lines:
    stripped = line.strip()
    if not skipped_heading and line.startswith('# '):
        skipped_heading = True
        continue
    if not started:
        if not stripped or stripped.startswith('[![') or stripped.startswith('!['):
            continue
        started = True
    if line.startswith('## '):
        if stripped in selected_sections:
            started_selected_section = True
        elif started_selected_section:
            break
        else:
            break
    out.append(line)

print('\n'.join(out).rstrip())
PY_README

  rewrite_plugin_links "$dest" "$repo" "$ref" "$source_path"
  rm -f "$tmp"
}
gen_plugin_markdown_doc() {
  local url="$1"
  local dest="$2"
  local fallback_link_title="$3"
  local fallback_weight="$4"
  local repo="$5"
  local ref="$6"
  local source_path="$7"
  local tmp

  tmp="$(mktemp)"
  mkdir -p "$(dirname "$dest")"
  curl -u "$GITHUB_USER:$GITHUB_TOKEN" -# -Lf "$url" > "$tmp"

  python3 - "$tmp" "$dest" "$fallback_link_title" "$fallback_weight" <<'PY'
import json
import re
import sys
from pathlib import Path

src, dest, fallback_link_title, fallback_weight = sys.argv[1:5]
text = Path(src).read_text()
front_matter = {}
body = text
front_matter_found = False


def unquote(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
        value = value[1:-1]
    return value


def parse_scalar_front_matter(raw, style):
    values = {}
    for line in raw.splitlines():
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if style == 'toml':
            match = re.match(r'^([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*(.+?)\s*$', line)
        else:
            match = re.match(r'^([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*(.+?)\s*$', line)
        if not match:
            continue
        key, value = match.groups()
        values[key.lower()] = unquote(value)
    return values

if text.startswith('---\n'):
    end = text.find('\n---', 4)
    if end != -1:
        front_matter_found = True
        front_matter = parse_scalar_front_matter(text[4:end], 'yaml')
        body = text[text.find('\n', end + 4) + 1:]
elif text.startswith('+++\n'):
    end = text.find('\n+++', 4)
    if end != -1:
        front_matter_found = True
        front_matter = parse_scalar_front_matter(text[4:end], 'toml')
        body = text[text.find('\n', end + 4) + 1:]
elif text.lstrip().startswith('{'):
    leading = len(text) - len(text.lstrip())
    decoder = json.JSONDecoder()
    try:
        parsed, end = decoder.raw_decode(text.lstrip())
    except json.JSONDecodeError:
        parsed = None
    if isinstance(parsed, dict):
        front_matter_found = True
        front_matter = {str(k).lower(): str(v) for k, v in parsed.items() if isinstance(v, (str, int, float, bool))}
        body = text[leading + end:].lstrip('\r\n')

body_lines = []
skipped_title = False
heading_title = ''
for line in body.splitlines():
    if line.startswith('<!-- '):
        continue
    if not skipped_title and line.startswith('# '):
        heading_title = line[2:].strip()
        skipped_title = True
        continue
    body_lines.append(line)

title = front_matter.get('title') or heading_title or fallback_link_title
link_title = front_matter.get('linktitle') or fallback_link_title
weight = front_matter.get('weight') or fallback_weight
description = front_matter.get('description') or 'Official Flux CLI plugin documentation.'


def yaml_scalar(value):
    return "'" + str(value).replace("'", "''") + "'"

out = [
    '---',
    f'title: {yaml_scalar(title)}',
]
if link_title:
    out.append(f'linkTitle: {yaml_scalar(link_title)}')
out.extend([
    f'description: {yaml_scalar(description)}',
    'importedDoc: true',
])
if weight:
    out.append(f'weight: {weight}')
out.extend(['---', ''])
out.extend(body_lines)
Path(dest).write_text('\n'.join(out).rstrip() + '\n')
PY

  rewrite_plugin_links "$dest" "$repo" "$ref" "$source_path"
  rm -f "$tmp"
}

import_plugin_docs() {
  local repo="$1"
  local slug="$2"
  local title="$3"
  local weight="$4"
  local ref
  local plugin_dir
  local docs_contents
  local readme_url
  local page_weight
  local name
  local url
  local page_slug
  local page_link_title

  ref="$(github_latest_release_tag "$repo")"
  echo "Using fluxcd/${repo} ${ref} release tag for plugin docs." >&2
  plugin_dir="${FLUX_PLUGIN_DIR}/${slug}"

  rm -rf "$plugin_dir"
  readme_url="$(github_download_url "$repo" "$ref" "README.md")"
  gen_plugin_readme_index "$readme_url" "${plugin_dir}/_index.md" "$title" "$weight" "$repo" "$ref" "README.md"

  docs_contents="$(mktemp)"
  github_contents "$repo" "$ref" "docs" "$docs_contents"

  page_weight=10
  jq -r '[.[] | select(.type == "file" and (.name | endswith(".md")))] | sort_by(.name)[] | [.name, .download_url] | @tsv' "$docs_contents" |
  while IFS=$'\t' read -r name url; do
    page_slug="${name%.md}"
    page_link_title="$(title_from_slug "$page_slug")"
    gen_plugin_markdown_doc "$url" "${plugin_dir}/${page_slug}.md" "$page_link_title" "$page_weight" "$repo" "$ref" "docs/${name}"
    page_weight=$((page_weight + 10))
  done

  rm -f "$docs_contents"
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
    TITLE="$(echo "$FIRST_LINE" | cut -d'<' -f2 | cut -d'>' -f2 | $SED 's/^\#\ //')"
  elif echo "$FIRST_LINE" | grep -E "^# "; then
    TITLE="$(echo "$FIRST_LINE" | $SED 's/^\#\ //')"
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
    grep -vE "^<!--" "$TMP" |$SED '1d' >> "$DEST"
    rm "$TMP"
  else
    mv "$TMP" "$DEST"
  fi
}

replace_or_append_section() {
  local dest="$1"
  local heading="$2"
  local section="$3"
  local tmp

  tmp="$(mktemp)"
  if ! awk -v heading="## ${heading}" -v section="${section}" '
    function print_section() {
      while ((getline line < section) > 0) {
        print line
      }
      close(section)
    }
    $0 == heading {
      print_section()
      in_section = 1
      replaced = 1
      next
    }
    in_section && /^## / {
      in_section = 0
    }
    !in_section {
      print
    }
    END {
      if (!replaced) {
        print ""
        print_section()
      }
    }
  ' "$dest" > "$tmp"; then
    rm -f "$tmp"
    fatal "Unable to update '${heading}' in ${dest}"
  fi
  mv "$tmp" "$dest"
}

gen_options_doc() {
  local url="$1"
  local dest="$2"
  local heading="$3"
  local tmp
  local section

  tmp="$(mktemp)"
  section="$(mktemp)"
  curl -u "$GITHUB_USER:$GITHUB_TOKEN" -# -Lf "$url" > "$tmp"

  if ! awk -v heading="## ${heading}" '
    /^<!-- / {
      next
    }
    $0 == "## Flags" {
      print heading
      in_flags = 1
      found = 1
      next
    }
    in_flags && /^## / {
      exit
    }
    in_flags {
      print
    }
    END {
      if (!found) {
        exit 2
      }
    }
  ' "$tmp" > "$section"; then
    rm -f "$tmp" "$section"
    fatal "Unable to extract controller options from ${url}"
  fi

  replace_or_append_section "$dest" "$heading" "$section"
  rm -f "$tmp" "$section"
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
  ctrl_out=${ctrl%%-*} # this is necessary to collect SC and SW under "source" and IAC and IRC under "image"

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

  if [ "${ctrl}" != "source-watcher" ] ; then
    for api_version in $(all_versions "${crds}") ; do
      doc_url=https://raw.githubusercontent.com/fluxcd/${ctrl}/${ctrl_version}/docs/api/${api_version}/${ctrl_short}.md
      gen_crd_doc "${doc_url}" "$COMPONENTS_DIR/${ctrl_out}/${api_out}/${api_version}.md" "HUGETABLE"
    done
  fi

  # Compute controller major and minor versions and release series branch.
  ctrl_major_version=$(echo "$ctrl_version" | cut -d'.' -f1)
  ctrl_minor_version=$(echo "$ctrl_version" | cut -d'.' -f2)
  release_branch="release/${ctrl_major_version}.${ctrl_minor_version}.x"

  for crd in ${crds} ; do
    name=${crd%%,*}
    name=${name%%.*}
    version=${crd##*,}
    gen_crd_doc "https://raw.githubusercontent.com/fluxcd/${ctrl}/${release_branch}/docs/spec/${version}/${name}.md" "$COMPONENTS_DIR/${ctrl_out}/${name}.md"
  done

  options_heading="Flags"
  case "${ctrl}" in
    source-controller)
      options_heading="Source controller flags"
      ;;
    source-watcher)
      options_heading="Source watcher flags"
      ;;
    image-automation-controller)
      options_heading="Image automation flags"
      ;;
    image-reflector-controller)
      options_heading="Image reflector flags"
      ;;
  esac
  gen_options_doc "https://raw.githubusercontent.com/fluxcd/${ctrl}/${release_branch}/docs/README.md" "$COMPONENTS_DIR/${ctrl_out}/options.md" "${options_heading}"

  # special cases for n-c
  if [ "${ctrl}" = "notification-controller" ] ; then
    # `Events` type is not a CRD but needs to be documented, too.
    gen_crd_doc "https://raw.githubusercontent.com/fluxcd/${ctrl}/${release_branch}/docs/spec/v1beta2/events.md" "$COMPONENTS_DIR/${ctrl_out}/events.md"
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
  gen_ctrl_docs "v${VERSION_FLUX}" "image-automation-controller"
  gen_ctrl_docs "v${VERSION_FLUX}" "image-reflector-controller"
}

{
  # source-watcher CRDs
  gen_ctrl_docs "v${VERSION_FLUX}" "source-watcher"
}

{
  # Flux CLI plugin docs
  rm -rf "${FLUX_PLUGIN_DIR:?}"/*
  write_plugin_section_index "${FLUX_PLUGIN_DIR}/_index.md" "Flux CLI Plugins" "Flux CLI Plugins" 81 \
    "Documentation for the official Flux CLI plugins."
  import_plugin_docs "flux-mirror" "flux-mirror" "Flux Mirror" 1
  import_plugin_docs "flux-schema" "flux-schema" "Flux Schema" 2
}

{
  # provide Flux install script
  if [ ! -d static ]; then
    mkdir static
  fi
  curl -u "$GITHUB_USER:$GITHUB_TOKEN" -s -# -Lf "https://raw.githubusercontent.com/fluxcd/flux2/v${VERSION_FLUX}/install/flux.sh" -o static/install.sh
}

