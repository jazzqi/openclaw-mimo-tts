#!/usr/bin/env bash
# Environment helper for xiaomi-mimo-tts scripts
# Sets SKILL_HOME to the parent directory of this scripts/ folder unless overridden

# Allow override
: "${SKILL_HOME:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Prefer XIAOMI_API_KEY, fall back to MIMO_API_KEY for compatibility
if [ -z "${XIAOMI_API_KEY}" ] && [ -n "${MIMO_API_KEY}" ]; then
  export XIAOMI_API_KEY="${MIMO_API_KEY}"
fi

export SKILL_HOME

# Helper: resolve a script path relative to SKILL_HOME
skill_path() {
  echo "$SKILL_HOME/$1"
}
