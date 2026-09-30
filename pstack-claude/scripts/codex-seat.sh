#!/usr/bin/env bash
# Run one pstack panel seat on OpenAI's Codex CLI.
#
# Usage: codex-seat.sh <read|write> <workdir> <prompt-file> <out-file> [model] [reasoning-effort]
#
# read   Codex may read anything and run commands, but cannot write.
# write  Codex may write inside <workdir> only (an arena candidate's worktree).
#
# The seat's final answer goes to <out-file>, the full run log to <out-file>.log.
# Exit 3: codex not installed. Exit 4: codex not logged in. Other non-zero: the run failed.
set -euo pipefail

[ $# -ge 4 ] || { echo "usage: codex-seat.sh <read|write> <workdir> <prompt-file> <out-file> [model] [reasoning-effort]" >&2; exit 2; }
mode=$1 workdir=$2 prompt=$3 out=$4 model=${5:-} effort=${6:-}

case "$mode" in
	read) sandbox=read-only ;;
	write) sandbox=workspace-write ;;
	*) echo "codex-seat: mode must be read or write, got '$mode'" >&2; exit 2 ;;
esac
[ -d "$workdir" ] || { echo "codex-seat: workdir '$workdir' does not exist" >&2; exit 2; }
[ -f "$prompt" ] || { echo "codex-seat: prompt file '$prompt' does not exist" >&2; exit 2; }

command -v codex >/dev/null 2>&1 || { echo "codex-seat: codex CLI is not installed (npm install -g @openai/codex)" >&2; exit 3; }
codex login status >/dev/null 2>&1 || { echo "codex-seat: codex is not logged in (run: codex login)" >&2; exit 4; }

args=(exec --sandbox "$sandbox" --cd "$workdir" --skip-git-repo-check --ephemeral --color never --output-last-message "$out")
[ -n "$model" ] && args+=(--model "$model")
[ -n "$effort" ] && args+=(--config "model_reasoning_effort=\"$effort\"")

if ! codex "${args[@]}" - < "$prompt" > "$out.log" 2>&1; then
	echo "codex-seat: codex exec failed, see $out.log" >&2
	exit 1
fi
[ -s "$out" ] || { echo "codex-seat: codex produced no final message, see $out.log" >&2; exit 1; }
