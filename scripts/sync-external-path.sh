#!/usr/bin/env bash

set -euo pipefail

source_path="${SOURCE_PATH:-}"
destination_path="${DESTINATION_PATH:-}"
delete_extra_files="${DELETE_EXTRA_FILES:-false}"

if [[ -z "$source_path" || -z "$destination_path" ]]; then
  echo "SOURCE_PATH and DESTINATION_PATH are required."
  exit 1
fi

if [[ ! -e "$source_path" ]]; then
  echo "Source path does not exist: $source_path"
  exit 1
fi

mkdir -p "$(dirname "$destination_path")"

if [[ -f "$source_path" ]]; then
  cp "$source_path" "$destination_path"
  exit 0
fi

mkdir -p "$destination_path"

rsync_args=(-a)
if [[ "$delete_extra_files" == "true" ]]; then
  rsync_args+=(--delete)
fi

rsync "${rsync_args[@]}" "$source_path"/ "$destination_path"/
