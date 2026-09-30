#!/usr/bin/env bash
# Run one pstack panel seat on OpenAI's Codex CLI.
#
# Usage: codex-seat.sh <read|write> <workdir> <prompt-file> <out-file> [model] [reasoning-effort]
#
# read   Codex may read anything and run commands, but cannot write.
# write  Codex may write inside <workdir> only (an arena candidate's worktree).
#
# The seat's final answer goes to <out-file>, the full run log to <out-file>.log.
# CODEX_SEAT_TIMEOUT caps the run in seconds (default 1200). A run that hits it exits 124.
# Exit 3: codex not installed. Exit 4: codex not logged in. Other non-zero: the run failed.
set -euo pipefail

[ $# -ge 4 ] || { echo "usage: codex-seat.sh <read|write> <workdir> <prompt-file> <out-file> [model] [reasoning-effort]" >&2; exit 2; }
mode=$1 workdir=$2 prompt=$3 out=$4 model=${5:-} effort=${6:-}

case "$mode" in
	read) sandbox=read-only ;;
	write) sandbox=workspace-write ;; # plus the /tmp exclusions below, so writes stay in <workdir>
	*) echo "codex-seat: mode must be read or write, got '$mode'" >&2; exit 2 ;;
esac
[ -d "$workdir" ] || { echo "codex-seat: workdir '$workdir' does not exist" >&2; exit 2; }
[ -f "$prompt" ] || { echo "codex-seat: prompt file '$prompt' does not exist" >&2; exit 2; }
out="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"
limit=${CODEX_SEAT_TIMEOUT:-1200}

command -v codex >/dev/null 2>&1 || { echo "codex-seat: codex CLI is not installed (npm install -g @openai/codex)" >&2; exit 3; }
codex login status >/dev/null 2>&1 || { echo "codex-seat: codex is not logged in (run: codex login)" >&2; exit 4; }

args=(exec --sandbox "$sandbox" --cd "$workdir" --skip-git-repo-check --ephemeral --color never --output-last-message "$out")
[ "$mode" = write ] && args+=(--config sandbox_workspace_write.exclude_slash_tmp=true --config sandbox_workspace_write.exclude_tmpdir_env_var=true)
[ -n "$model" ] && args+=(--model "$model")
[ -n "$effort" ] && args+=(--config "model_reasoning_effort=\"$effort\"")

rm -f "$out" "$out.timeout"
set -m # give codex its own process group, so a timeout stops its children too
codex "${args[@]}" - < "$prompt" > "$out.log" 2>&1 &
pid=$!
set +m
(
	trap 'kill "$nap" 2>/dev/null; exit 0' TERM
	sleep "$limit" & nap=$!
	wait "$nap"
	touch "$out.timeout"
	kill -TERM -- "-$pid" 2>/dev/null
) &
watchdog=$!
status=0
wait "$pid" || status=$?
kill "$watchdog" 2>/dev/null || true
wait "$watchdog" 2>/dev/null || true
if [ -e "$out.timeout" ]; then
	rm -f "$out.timeout"
	echo "codex-seat: codex ran past ${limit}s and was stopped, see $out.log" >&2
	exit 124
fi
if [ "$status" -ne 0 ]; then
	echo "codex-seat: codex exec failed, see $out.log" >&2
	exit 1
fi
[ -s "$out" ] || { echo "codex-seat: codex produced no final message, see $out.log" >&2; exit 1; }
