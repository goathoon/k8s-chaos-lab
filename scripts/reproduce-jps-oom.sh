#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${SCENARIO:-memory/probe-induced-oom}"
"$(dirname "$0")/trigger-scenario.sh" "${SCENARIO}"
