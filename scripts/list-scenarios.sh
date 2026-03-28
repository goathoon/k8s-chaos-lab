#!/usr/bin/env bash
set -euo pipefail

find scenarios -name scenario.yaml | sort | while read -r file; do
  scenario_path="${file%/scenario.yaml}"
  scenario_name="${scenario_path#scenarios/}"
  description="$(awk -F ': *' '$1 == "description" {print substr($0, index($0, ":") + 2)}' "${file}")"
  printf "%-28s %s\n" "${scenario_name}" "${description}"
done
