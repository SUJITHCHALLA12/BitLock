#!/usr/bin/env bash
set -euo pipefail

# Detect likely credential assignments while permitting names and documentation.
pattern="(?i)(password|secret|api[_-]?key|access[_-]?token|service[_-]?role)[[:space:]]*[:=][[:space:]]*['\"][A-Za-z0-9_./+=-]{16,}['\"]"
if ! command -v rg >/dev/null 2>&1; then
  echo "Secret scan could not run: ripgrep (rg) is required." >&2
  exit 2
fi

if rg -n --pcre2 "$pattern" --glob '!*.lock' --glob '!docs/**' .; then
  echo "Possible hardcoded credential found." >&2
  exit 1
else
  scan_status=$?
  if [[ $scan_status -ne 1 ]]; then
    echo "Secret scan failed with ripgrep exit code $scan_status." >&2
    exit "$scan_status"
  fi
fi
echo "Secrets hygiene scan passed."
