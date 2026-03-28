#!/usr/bin/env bash
set -euo pipefail

SCENARIO_ROOT="${SCENARIO_ROOT:-scenarios}"
DEFAULT_NAMESPACE="${DEFAULT_NAMESPACE:-chaos-lab}"

scenario_name="${1:-${SCENARIO:-}}"

if [[ -z "${scenario_name}" ]]; then
  echo "usage: scenario name is required" >&2
  exit 1
fi

scenario_dir="${SCENARIO_ROOT}/${scenario_name}"
scenario_meta_file="${scenario_dir}/scenario.yaml"

if [[ ! -d "${scenario_dir}" ]]; then
  echo "scenario not found: ${scenario_name}" >&2
  exit 1
fi

if [[ ! -f "${scenario_meta_file}" ]]; then
  echo "scenario metadata not found: ${scenario_meta_file}" >&2
  exit 1
fi

scenario_meta() {
  local key="${1}"
  awk -F ': *' -v target="${key}" '$1 == target {print substr($0, index($0, ":") + 2)}' "${scenario_meta_file}" | head -n 1
}

scenario_namespace() {
  local value
  value="$(scenario_meta namespace || true)"
  if [[ -n "${value}" ]]; then
    echo "${value}"
  else
    echo "${DEFAULT_NAMESPACE}"
  fi
}

scenario_deployment() {
  scenario_meta deployment
}

scenario_rollout_mode() {
  local value
  value="$(scenario_meta rollout || true)"
  if [[ -n "${value}" ]]; then
    echo "${value}"
  else
    echo "stable"
  fi
}

scenario_description() {
  scenario_meta description
}

scenario_trigger_script() {
  echo "${scenario_dir}/trigger.sh"
}

scenario_verify_script() {
  echo "${scenario_dir}/verify.sh"
}

scenario_exists_script() {
  local path="${1}"
  [[ -f "${path}" && -x "${path}" ]]
}

scenario_pod() {
  local namespace deployment selector
  namespace="$(scenario_namespace)"
  deployment="$(scenario_deployment)"
  selector="app=${deployment}"
  kubectl -n "${namespace}" get pod -l "${selector}" -o jsonpath='{.items[0].metadata.name}'
}
