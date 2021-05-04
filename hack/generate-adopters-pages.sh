#!/bin/sh

SCRIPT_NAME="./hack/generate-adopters-pages.sh"
ADOPTERS_DIR="./adopters"
CONTENT_DIR="content/en"

if [ ! -x "$SCRIPT_NAME" ]; then
    echo "Please run this script from top-level of the repository."
    exit 1
fi

YQ=$(command -v yq)
if [ ! "$YQ" ]; then
    if [ -x "./yq" ]; then
        YQ="./yq"
    else
        echo "Please install 'yq'."
        exit 1
    fi
fi

for fn in "$ADOPTERS_DIR"/*.yaml; do
    PAGE_NAME=$(${YQ} eval '.adopters.url' "$fn")
    PAGE_DIR=$(realpath "$(dirname "$CONTENT_DIR/${PAGE_NAME}")")
    if [ ! -d "$PAGE_DIR" ]; then
        mkdir -p "$PAGE_DIR"
    fi
    PAGE_FN=$(realpath "$CONTENT_DIR/${PAGE_NAME}.md")
    PAGE_TITLE=$(${YQ} eval '.adopters.project' "$fn")
    PAGE_DESC=$(${YQ} eval '.adopters.project' "$fn")
    {
        echo "---"
        echo "title: ${PAGE_TITLE} Adopters"
        echo "type: page"
        echo "---"
        echo
        echo "${PAGE_DESC}"
        echo
        echo "{{< cardcolumns >}}"
        echo
    } > "$PAGE_FN"
    HOW_MANY=$(${YQ} eval '.adopters.companies | length' "$fn")
    MINUS_ONE=$((HOW_MANY - 1))
    for i in $(seq 0 "${MINUS_ONE}"); do
        COMP_NAME="$(${YQ} eval ".adopters.companies[${i}].name" "$fn")"
        COMP_URL="$(${YQ} eval ".adopters.companies[${i}].url" "$fn")"
        COMP_LOGO="$(${YQ} eval ".adopters.companies[${i}].logo" "$fn")"
        {
            echo "{{% card header=\"[${COMP_NAME}](${COMP_URL})\" %}}"
            echo "![${COMP_NAME}](${COMP_LOGO})"
            echo "{{% /card %}}"
            echo
        } >> "$PAGE_FN"
    done
    {
        echo "{{< /cardcolumns >}}"
        echo
    } >> "$PAGE_FN"
done

cp -r "$ADOPTERS_DIR/logos" static/img
