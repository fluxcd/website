#!/bin/sh

SCRIPT_NAME="./hack/generate-adopters-pages.sh"
ADOPTERS_DIR="./adopters"
CONTENT_DIR="content/en"

if [ ! -x "$SCRIPT_NAME" ]; then
    echo "Please run this script from top-level of the repository."
    exit 1
fi

if [ ! "$(which yq)" ]; then
    echo "Please install 'yq'."
    exit 1
fi

for fn in "$ADOPTERS_DIR"/*.yaml; do
    PAGE_NAME=$(yq eval '.adopters.url' "$fn")
    PAGE_DIR=$(realpath "$(dirname "$CONTENT_DIR/${PAGE_NAME}")")
    if [ ! -d "$PAGE_DIR" ]; then
        mkdir -p "$PAGE_DIR"
    fi
    PAGE_FN=$(realpath "$CONTENT_DIR/${PAGE_NAME}.md")
    PAGE_TITLE=$(yq eval '.adopters.project' "$fn")
    PAGE_DESC=$(yq eval '.adopters.project' "$fn")
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
    HOW_MANY=$(yq eval '.adopters.companies | length' "$fn")
    for i in $(seq 0 "$(echo "${HOW_MANY}-1" | bc)"); do
        COMP_NAME="$(yq eval ".adopters.companies[${i}].name" "$fn")"
        COMP_URL="$(yq eval ".adopters.companies[${i}].url" "$fn")"
        COMP_LOGO="$(yq eval ".adopters.companies[${i}].logo" "$fn")"
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
