#!/usr/bin/env bash
set -euo pipefail

# INPUT_TAG is data passed through the workflow environment, never shell source.
if [[ "${GITHUB_EVENT_NAME:-}" == "workflow_dispatch" ]]; then
  requested_tag="${INPUT_TAG:-}"
elif [[ "${GITHUB_REF_TYPE:-}" == "tag" ]]; then
  requested_tag="${GITHUB_REF_NAME:-}"
else
  echo "::error::Release source must be an explicit tag." >&2
  exit 1
fi
if [[ -z "$requested_tag" ]] || ! git check-ref-format "refs/tags/$requested_tag"; then
  echo "::error::Invalid release tag." >&2
  exit 1
fi

# Resolve the remote tag once. Every later checkout uses the resulting SHA.
git fetch --no-tags --force origin "+refs/tags/$requested_tag:refs/tags/$requested_tag"
source_sha="$(git rev-parse --verify "refs/tags/$requested_tag^{commit}")"
if [[ ! "$source_sha" =~ ^[a-f0-9]{40}$ ]]; then
  echo "::error::Release tag did not resolve to a commit." >&2
  exit 1
fi
printf 'source_sha=%s\ntag=%s\n' "$source_sha" "$requested_tag" >> "$GITHUB_OUTPUT"
