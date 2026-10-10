#!/usr/bin/env bash
set -euo pipefail

# Detect likely hardcoded credentials while permitting names and documentation.
# Matches assignments like: password = "....", api-key: '....' (16+ char quoted value)
pattern="(?i)(password|secret|api[_-]?key|access[_-]?token|service[_-]?role)[[:space:]]*[:=][[:space:]]*['\"][A-Za-z0-9_./+=-]{16,}['\"]"

# Run one scanner over the repo.
# Prints any matches. Returns 0 when clean, 1 when a possible secret was
# found, 2 when the scanner itself errored.
scan() {
  case "$1" in
    rg)
      rg -n --pcre2 "$pattern" --glob '!*.lock' --glob '!docs/**' .
      ;;
    grep)
      grep -rIn -P "$pattern" \
        --exclude='*.lock' --exclude-dir=docs --exclude-dir=.git .
      ;;
  esac
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    return 1 # scanner printed matches -> possible secret
  elif [[ $rc -eq 1 ]]; then
    return 0 # no matches -> clean
  else
    return 2 # scanner itself errored
  fi
}

for tool in rg grep; do
  if [[ "$tool" == "rg" ]] && ! command -v rg >/dev/null 2>&1; then
    continue
  fi
  set +e
  scan "$tool"
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    echo "Secrets hygiene scan passed (via $tool)."
    exit 0
  elif [[ $rc -eq 1 ]]; then
    echo "Possible hardcoded credential found (via $tool)." >&2
    exit 1
  else
    echo "Scanner '$tool' errored (exit code $rc); trying next scanner." >&2
  fi
done

echo "Secret scan could not run: no working scanner (rg or grep -P) available." >&2
exit 2
