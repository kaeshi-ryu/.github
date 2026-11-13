#!/usr/bin/env bash
# Runs the "Check bun supply-chain settings" step of bun-ci.yml on every example repository of
# this folder and compares the result with the case's `.expect` file.
#
# Usage: run.sh <check script>, the script being the `run` block of that step, extracted from
# bun-ci.yml by the CI so that the tested code is the shipped one.
#
# `<case>.expect`: first line `pass` or `fail`; for `fail`, each following line is a fixed string
# that must appear in the output, one per expected `::error` line, and the output must hold
# exactly that many `::error` lines.
set -euo pipefail

check=$(realpath "$1")
here=$(dirname "$(realpath "$0")")
work=$(mktemp -d)
failures=0
ran=0

for dir in "$here"/*/; do
  name=$(basename "$dir")
  ran=$((ran + 1))
  expect="$here/$name.expect"
  out="$work/$name.out"
  code=0
  (cd "$dir" && bash "$check") >"$out" 2>&1 || code=$?
  ok=1
  errors=$(grep -c '^::error' "$out" || true)
  case $(head -n 1 "$expect") in
    pass)
      if [ "$code" -ne 0 ] || [ "$errors" -ne 0 ]; then ok=0; fi
      ;;
    fail)
      if [ "$code" -eq 0 ]; then ok=0; fi
      wanted=0
      while IFS= read -r want; do
        wanted=$((wanted + 1))
        if ! grep -qF -- "$want" "$out"; then
          echo "  missing: $want"
          ok=0
        fi
      done < <(tail -n +2 "$expect")
      if [ "$errors" -ne "$wanted" ]; then
        echo "  expected $wanted ::error lines, got $errors"
        ok=0
      fi
      ;;
    *)
      echo "  bad expect file: $expect"
      ok=0
      ;;
  esac
  if [ "$ok" -eq 1 ]; then
    echo "ok   $name"
  else
    echo "FAIL $name (exit $code)"
    sed 's/^/     /' "$out"
    failures=$((failures + 1))
  fi
done

rm -rf "$work"
echo "$((ran - failures))/$ran passed"
if [ "$ran" -eq 0 ] || [ "$failures" -ne 0 ]; then exit 1; fi
