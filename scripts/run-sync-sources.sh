#!/usr/bin/env bash

set -euo pipefail

config_path="${CONFIG_PATH:-.github/sync-sources.json}"
source_name_filter="${SOURCE_NAME:-}"
sync_token="${SYNC_SOURCE_TOKEN:-}"

if [[ ! -f "$config_path" ]]; then
  echo "Sync config file not found: $config_path"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed."
  exit 1
fi

if [[ -z "$sync_token" ]]; then
  echo "SYNC_SOURCE_TOKEN is required."
  exit 1
fi

source_count="$(jq '.sources | length' "$config_path")"
if [[ "$source_count" -eq 0 ]]; then
  echo "No sources configured in $config_path"
  exit 1
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

selected_count=0

for index in $(seq 0 $((source_count - 1))); do
  name="$(jq -r ".sources[$index].name // \"\"" "$config_path")"
  repo="$(jq -r ".sources[$index].repo // \"\"" "$config_path")"
  ref="$(jq -r ".sources[$index].ref // \"main\"" "$config_path")"
  source_path="$(jq -r ".sources[$index].source_path // \"\"" "$config_path")"
  destination_path="$(jq -r ".sources[$index].destination_path // \"\"" "$config_path")"
  delete_extra_files="$(jq -r ".sources[$index].delete_extra_files // false" "$config_path")"

  if [[ -n "$source_name_filter" && "$name" != "$source_name_filter" ]]; then
    continue
  fi

  if [[ -z "$name" || -z "$repo" || -z "$source_path" || -z "$destination_path" ]]; then
    echo "Each source must define name, repo, source_path, and destination_path."
    exit 1
  fi

  selected_count=$((selected_count + 1))

  clone_dir="$workdir/$name"
  repo_url="https://x-access-token:${sync_token}@github.com/${repo}.git"

  echo "Syncing $name from $repo:$source_path to $destination_path"

  git clone --filter=blob:none --sparse --no-checkout "$repo_url" "$clone_dir"
  git -C "$clone_dir" sparse-checkout set --no-cone "$source_path"
  git -C "$clone_dir" checkout "$ref"

  SOURCE_PATH="$clone_dir/$source_path" \
  DESTINATION_PATH="$destination_path" \
  DELETE_EXTRA_FILES="$delete_extra_files" \
  ./scripts/sync-external-path.sh

  rm -rf "$clone_dir"
done

if [[ -n "$source_name_filter" && "$selected_count" -eq 0 ]]; then
  echo "No source named '$source_name_filter' was found in $config_path"
  exit 1
fi
