#!/bin/sh

COMPONENTS_DIR="content/en/docs/components"
FLUX_DIR="content/en/docs/cmd"

controller_version() {
  if [ ! "$(command -v jq)" ]; then
    echo "Please install 'jq'."
    exit 1
  fi
  curl -s "https://registry.hub.docker.com/v2/repositories/fluxcd/$1/tags/?page_size=1" | jq -r .results[].name
}

gen_crd_doc() {
  URL="$1"
  TMP="$(mktemp)"
  DEST="$2"
  curl -# -Lf "$URL" > "$TMP"
  TITLE="$(head -n1 "$TMP"  | cut -d'<' -f2 | cut -d'>' -f2)"

  {
    echo "---"
    echo "title: $TITLE"
    echo "---"
  } >> "$DEST"
  cat "$TMP" >> "$DEST"
  rm "$TMP"
}

{
  # source-controller CRDs
  SOURCE_VER="$(controller_version source-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/api/source.md" "$COMPONENTS_DIR/source/api.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/spec/v1beta1/gitrepositories.md" "$COMPONENTS_DIR/source/gitrepositories.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/spec/v1beta1/helmrepositories.md" "$COMPONENTS_DIR/source/helmrepositories.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/spec/v1beta1/helmcharts.md" "$COMPONENTS_DIR/source/helmcharts.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/source-controller/$SOURCE_VER/docs/spec/v1beta1/buckets.md" "$COMPONENTS_DIR/source/buckets.md"
}

{
  # kustomize-controller CRDs
  KUSTOMIZE_VER="$(controller_version kustomize-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/kustomize-controller/$KUSTOMIZE_VER/docs/api/kustomize.md" "$COMPONENTS_DIR/kustomize/api.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/kustomize-controller/$KUSTOMIZE_VER/docs/spec/v1beta1/kustomization.md" "$COMPONENTS_DIR/kustomize/kustomization.md"
}

{
  # helm-controller CRDs
  HELM_VER="$(controller_version helm-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/helm-controller/$HELM_VER/docs/api/helmrelease.md" "$COMPONENTS_DIR/helm/api.md"
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
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-reflector-controller/$IMG_REFL_VER/docs/api/image-reflector.md" "$COMPONENTS_DIR/image/reflector-api.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-reflector-controller/$IMG_REFL_VER/docs/spec/v1alpha1/imagerepositories.md" "$COMPONENTS_DIR/image/imagerepositories.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-reflector-controller/$IMG_REFL_VER/docs/spec/v1alpha1/imagepolicies.md" "$COMPONENTS_DIR/image/imagepolicies.md"

  IMG_AUTO_VER="$(controller_version image-automation-controller)"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-automation-controller/$IMG_AUTO_VER/docs/api/image-automation.md" "$COMPONENTS_DIR/image/automation-api.md"
  gen_crd_doc "https://raw.githubusercontent.com/fluxcd/image-automation-controller/$IMG_AUTO_VER/docs/spec/v1alpha1/imageupdateautomations.md" "$COMPONENTS_DIR/image/imageupdateautomations.md"
}

{
  # get flux cmd docs
  TMP="$(mktemp -d)"
  git clone -q --depth 1 git@github.com:fluxcd/flux2 "$TMP"
  if [ ! -d "$FLUX_DIR" ]; then
    mkdir "$FLUX_DIR"
  fi
  cp -r "$TMP"/docs/cmd/* $FLUX_DIR
  rm -rf "$TMP"
  exit 0
}
