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

PAGE_FN=$(realpath "$CONTENT_DIR/adopters.md")
{
    echo "---"
    echo "title: Flux Adopters"
    echo "type: page"
    echo "---"
    echo
    echo "# Flux Adopters"
    echo "Organisations below all are using the [Flux family of projects](https://fluxcd.io) in production."
    echo "  "
    echo "We are happy and proud to have you all as part of our community! 💖"

} > "$PAGE_FN"

for fn in "$ADOPTERS_DIR"/*.yaml; do
    SECTION_ID=$(basename "$fn" .yaml)
    SECTION_TITLE=$(${YQ} eval '.adopters.project' "$fn")
    PAGE_DESC=$(${YQ} eval '.adopters.description' "$fn")
    {
        echo
        echo "<h2 id=\"${SECTION_ID}\">${SECTION_TITLE} Adopters</h2>"
        echo
        echo "${PAGE_DESC}"
        echo
        echo "{{< cardcolumns >}}"
        echo
    } >> "$PAGE_FN"
    HOW_MANY=$(${YQ} eval '.adopters.companies | length' "$fn")
    MINUS_ONE=$((HOW_MANY - 1))
    for i in $(seq 0 "${MINUS_ONE}"); do
        COMP_NAME="$(${YQ} eval ".adopters.companies[${i}].name" "$fn")"
        COMP_URL="$(${YQ} eval ".adopters.companies[${i}].url" "$fn")"
        COMP_LOGO="$(${YQ} eval ".adopters.companies[${i}].logo" "$fn")"
        if [ "${COMP_LOGO}" = "null" ]; then
            COMP_LOGO="logos/logo-generic.png"
        fi
        if echo "${COMP_LOGO}" | grep -qvE "^https:"; then
            if [ ! -f "${ADOPTERS_DIR}/${COMP_LOGO}" ]; then
                echo "${ADOPTERS_DIR}/${COMP_LOGO} not found."
                exit 1
            fi
            COMP_LOGO="/img/${COMP_LOGO}"
        fi
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
