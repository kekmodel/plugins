#!/usr/bin/env bash
# Regenerate agents/<model>-<effort>.md, one pinned-effort pstack agent per pair.
# The Agent tool cannot set reasoning effort per call, so each pair needs its own agent.
# Usage: scripts/gen-effort-agents.sh [model ...]   (default: opus fable sonnet)
set -euo pipefail
cd "$(dirname "$0")/.."
if [ $# -gt 0 ]; then models=("$@"); else models=(opus fable sonnet); fi
for model in "${models[@]}"; do
	for effort in low medium high xhigh max; do
		cat > "agents/$model-$effort.md" <<AGENT
---
name: $model-$effort
description: pstack subagent pinned to $model at $effort effort, for roles set to \`$model:$effort\`.
model: $model
effort: $effort
---

# pstack subagent ($model, $effort effort)

Follow the brief you are given exactly, including any read-only instruction.

When the brief gives the path of poteto-mode's \`SKILL.md\`, or says it is a poteto-mode playbook step, you are a poteto-agent. Read that file in full before any work (without a path, find it with \`find ~/.claude -path '*/skills/poteto-mode/SKILL.md' 2>/dev/null\` and pick the one under a pstack plugin directory), including its inline Principles index. Read a leaf \`principle-*\` skill whenever you apply that principle. It lives next to poteto-mode, at \`../principle-<name>/SKILL.md\` from poteto-mode's directory.

You are a subagent, so you cannot spawn subagents. Do each step inline. When a step calls for fan-out, return and say what the parent should spawn.
AGENT
	done
done
