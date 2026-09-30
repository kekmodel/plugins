---
name: setup-pstack
description: Configure which models pstack uses per role and at what budget. Detects the models the Agent tool accepts and writes a config file that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
disable-model-invocation: true
---

# Setup pstack

Write `~/.claude/pstack-models.md`, the file every pstack skill reads to pick a model per role.

## Steps

### 1. Detect available models

The Agent tool's `model` parameter lists the values this session accepts. Read them from the tool definition. The usual set is `opus`, `sonnet`, `haiku`, and on some accounts `fable`. If you cannot tell, ask the user which ones they have. Never write a model you have not confirmed is available. The alias `inherit` is always valid. It means: omit `model` so the subagent runs on the parent chat model.

Also check for OpenAI's Codex CLI with `command -v codex && codex login status`. When both succeed, `codex:<model>:<effort>` is available for panel roles (arena runners, arena cross-judge pool, architect runners, interrogate reviewers). A Codex seat runs through `scripts/codex-seat.sh`, not a subagent. When Codex is missing or logged out, say so, and a configured Codex seat falls back to a `sonnet` subagent at run time.

### 2. Load current state

The default role-to-model mapping is the file shape shown in step 5 below. If `~/.claude/pstack-models.md` already exists, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from those defaults. A line whose role is not in step 5 is from a retired role. Drop it.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Use AskUserQuestion. Offer these three options with these exact labels, and name the current budget when the file records one.

- `balanced — opus judges, sonnet codes` (the defaults in step 5)
- `max — opus everywhere`
- `lean — sonnet judges, haiku codes`

**(b) Apply it.** Build the working table from the defaults in step 5, and on a re-run keep any role the user changed away from the defaults.

- `balanced` leaves the defaults as they are.
- `max` sets every single-model role to `opus`. Panel lists keep their mix so reviewers still differ.
- `lean` sets `judgment and prose`, `hardest tasks`, and every synthesizer or explainer role to `sonnet`, every code and worker role to `haiku`, and every panel list to `sonnet, haiku`.

If a value is not in the detected set, use the next model down the ladder `opus` > `fable` > `sonnet` > `haiku` that is detected, and mark the role as changed. `inherit` does not change.

**(c) Show the roles and confirm.** Show every role with its model. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models plus `inherit`. Use AskUserQuestion. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one subagent runs per entry, alias entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena picks one value from it that differs from the parent's model when possible. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every model written must be in the detected set. `inherit` always passes. If a chosen model is not available, stop and ask again.

### 5. Write the file

Write `~/.claude/pstack-models.md` with a `# budget` line and one line per role, using the same labels poteto-mode uses. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# Values: opus, sonnet, haiku, fable, or inherit (omit the Agent `model` so the role runs on the parent chat model).
# Alias entries in a panel list still count toward its fan-out.
# budget: balanced
feature, refactoring: sonnet
bug-fix: sonnet
perf-issue: sonnet
hillclimb: sonnet
judgment and prose: opus
hardest tasks: opus
how explorer: sonnet
how explainer: opus
why investigators: sonnet
why synthesizer: opus
reflect tooling: sonnet
reflect judgment, divergent, synthesizer: opus
arena runners: opus, fable, sonnet
arena cross-judge pool: opus, fable, sonnet
swarm workers: sonnet
architect runners: opus, fable, sonnet
interrogate reviewers: opus, fable, sonnet
```

### 6. Confirm

Tell the user the file was written and that skills read it the next time they spawn a subagent. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? Run /pstack:create-verification-skill and it will generate one." It is user-only, so you cannot start it yourself. On no, move on without pushing.
