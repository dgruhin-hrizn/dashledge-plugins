#!/usr/bin/env bash
# Check a pull request against the registry's rules. Runs in CI with no secrets.
#
# A submission only adds files: listings/<id>/<version>.json and screenshots beside it.
# Each listing's package is downloaded from the author's GitHub release, checked against
# its sha256 and validated with dashledge-package, the same code the app runs. Anything
# else (revoked.json, MAINTAINERS, scripts, workflows) is a maintainer's change.
#
# Environment: BASE (base commit), AUTHOR (PR author's login), DASHLEDGE_PACKAGE (the
# tool), optional LOCAL_PACKAGES (a folder of <id>/<version>.zip to use instead of
# downloading, for testing), GITHUB_STEP_SUMMARY.
set -euo pipefail

tool=${DASHLEDGE_PACKAGE:-dashledge-package}
summary=${GITHUB_STEP_SUMMARY:-/dev/stdout}
author=$(printf '%s' "${AUTHOR:?}" | tr '[:upper:]' '[:lower:]')
maintainers=$(grep -v '^#' MAINTAINERS | tr '[:upper:]' '[:lower:]' | paste -sd, -)
is_maintainer() { [[ ",$maintainers," == *",$author,"* ]]; }
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failed=0
fail() { echo "::error file=$1::$2"; printf -- '- ❌ `%s`: %s\n' "$1" "$2" >> "$summary"; failed=1; }

echo "# Registry check" >> "$summary"
while IFS=$'\t' read -r change path; do
  [[ -z "$path" ]] && continue
  if [[ "$change" != A ]]; then
    if is_maintainer; then continue; fi
    fail "$path" "Submissions only add files. Published listings never change; publish a new version instead."
    continue
  fi
  case "$path" in
    listings/*/*.json)
      id=$(cut -d/ -f2 <<< "$path")
      version=$(basename "$path" .json)
      publisher=$(jq -r '.publisher // ""' "$path")
      if [[ "$publisher" != "$author" ]] && ! is_maintainer; then
        fail "$path" "The listing's publisher ($publisher) must be the pull request's author ($author)."
        continue
      fi
      zip="$work/$id/$version.zip"
      mkdir -p "$(dirname "$zip")"
      if [[ -n "${LOCAL_PACKAGES:-}" && -f "$LOCAL_PACKAGES/$id/$version.zip" ]]; then
        cp "$LOCAL_PACKAGES/$id/$version.zip" "$zip"
      else
        url="https://github.com/$(jq -r .source.repo "$path")/releases/download/$(jq -r .source.tag "$path")/$(jq -r .source.asset "$path")"
        if ! curl -fsSL --proto '=https' --max-filesize 8388608 --retry 2 "$url" -o "$zip"; then
          fail "$path" "Could not download $url. Publish the release with the ZIP attached first."
          continue
        fi
      fi
      if ! "$tool" check-listing "$path" "$zip" --maintainers "$maintainers" >> "$summary" 2> "$work/error"; then
        fail "$path" "$(cat "$work/error")"
      fi
      ;;
    listings/*/*.png|listings/*/*.jpg|listings/*/*.jpeg)
      ;;
    *)
      if ! is_maintainer; then fail "$path" "Submissions add files under listings/ only."; fi
      ;;
  esac
done < <(git diff --name-status --no-renames "${BASE:?}"...HEAD)

if [[ $failed == 0 ]]; then
  echo "All checks passed. A maintainer reviews the grants above before merging." >> "$summary"
fi
exit $failed
