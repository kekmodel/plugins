# Role values

Every pstack skill that spawns a model reads its values this way. Skills link here instead of restating it.

## Where a value comes from

Each spawn names a role line in `~/.claude/pstack-models.md` and a default.

1. When the user names a model, effort, or panel for this run (for example "interrogate with opus:max and codex:astra:xhigh"), use that for this run.
2. Otherwise use the role line's value.
3. When the file or the line is missing, use the skill's default.

A panel line is a comma-separated list. One seat runs per entry, so the list length sets the seat count.

## What a value means

| Value | How to spawn it |
|---|---|
| `opus`, `sonnet`, `haiku`, `fable` | The step's usual `subagent_type` with that `model`. It runs at the session's effort. |
| `<model>:<effort>`, such as `opus:xhigh` | `subagent_type: pstack:<model>-<effort>` with `model` unset, since that agent pins both. If the Agent tool does not list that agent, use the usual type with `model: <model>` and say the effort was not applied. |
| `inherit` | The usual type with `model` unset, so it runs on the parent chat model. |
| `codex`, `codex:<model>`, `codex:<model>:<effort>` | A Codex seat. See below. Panel roles only. |

The `pstack:<model>-<effort>` agents keep every tool, MCP included. When a brief gives poteto-mode's `SKILL.md` path, they act as `poteto-agent`.

## When a value fails

If the Agent tool rejects a model (a missing effort agent is handled in the table above), run that seat as the step's usual type with `model: sonnet` and say so. That is the same fallback a failed Codex seat gets. If `sonnet` is rejected too, leave `model` unset and say so. Never treat `inherit` as a rejected value. Do not block the run on a model problem.

When two or more seats end up on the same model, their distinct angles or directions keep them independent. Never merge two seats into one.

## Codex seats

A Codex seat runs on OpenAI's Codex CLI through `scripts/codex-seat.sh`, which sits in this plugin next to this `references/` directory. Codex starts in the given directory and reads the codebase itself.

1. Write the seat's prompt to a file. Name large diffs by range or path instead of pasting them.
2. Run `<plugin>/scripts/codex-seat.sh <read|write> <workdir> <prompt file> <out file> [<model>] [<effort>]` with the Bash tool's `run_in_background: true`, in the same message as the subagent spawns. `read` is for reviewers and judges, with `<workdir>` the repo root. `write` is for a seat that produces files, with `<workdir>` its own output directory, and Codex may write nowhere else.
3. Read the answer from `<out file>`.

Exit 3 means Codex is not installed, 4 means it is not logged in, 124 means it ran past `CODEX_SEAT_TIMEOUT` (default 1200 seconds), and any other non-zero exit means the run failed. In each case, run that seat as a `sonnet` subagent and say so.

Panel skills spawn subagents, so they run in the main session, never inside a subagent.
