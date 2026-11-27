#!/usr/bin/env bash
# Build, sign and stage the Marketplace catalog. Runs in CI on every merge to main and
# weekly, so the catalog is re-signed before it expires.
#
# site/ is a checkout of the gh-pages branch. Packages already published there are
# reused, so an author can't change what a published version contains by replacing their
# release asset; only new versions are downloaded.
#
# Environment: DASHLEDGE_PACKAGE (the tool), CATALOG_SIGNING_KEY (the private key, as
# keygen writes it), optional SITE (default site), LIFETIME_DAYS (default 30).
set -euo pipefail

tool=${DASHLEDGE_PACKAGE:-dashledge-package}
site=${SITE:-site}
: "${CATALOG_SIGNING_KEY:?Set the CATALOG_SIGNING_KEY secret}"
maintainers=$(grep -v '^#' MAINTAINERS | tr '[:upper:]' '[:lower:]' | paste -sd, -)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p listings "$site"

"$tool" sources --listings listings | while read -r id version url sha; do
  dest="$work/packages/$id/$version.zip"
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$site/v1/packages/$id/$version.zip" ]]; then
    cp "$site/v1/packages/$id/$version.zip" "$dest"
  else
    curl -fsSL --proto '=https' --max-filesize 8388608 --retry 2 "$url" -o "$dest"
  fi
done
mkdir -p "$work/packages"

args=(catalog --listings listings --packages "$work/packages" --out "$work/v1"
      --maintainers "$maintainers" --lifetime-days "${LIFETIME_DAYS:-30}")
[[ -f "$site/v1/catalog.json" ]] && args+=(--previous "$site/v1/catalog.json")
[[ -f revoked.json ]] && args+=(--revoked revoked.json)
"$tool" "${args[@]}"

key="$work/catalog.key"
( umask 077; printf '%s\n' "$CATALOG_SIGNING_KEY" > "$key" )
"$tool" sign "$work/v1/catalog.json" --key "$key"
rm -f "$key"

rm -rf "$site/v1"
cp -R "$work/v1" "$site/v1"
touch "$site/.nojekyll"
echo "Staged catalog sequence $(jq .sequence "$site/v1/catalog.json") in $site/v1."
