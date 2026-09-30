---
name: setup-pstack
description: Configure which models pstack uses per role, at what reasoning effort, and whether a Codex CLI seat joins the review panels. Detects the models the Agent tool accepts and writes a config file that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
disable-model-invocation: true
---

# Setup pstack

Write `~/.claude/pstack-models.md`, the file every pstack skill reads to pick a model per role.

## Steps

### 1. Detect available models

The Agent tool's `model` parameter lists the models this session accepts. Read them from the tool definition. The usual set is `opus`, `sonnet`, `haiku`, and on some accounts `fable`. If you cannot tell, ask the user which ones they have. Never write a model you have not confirmed is available. The alias `inherit` is always valid. It means: omit `model` so the subagent runs on the parent chat model.

A value can pin a reasoning effort as `<model>:<effort>`. The skills run it on the plugin agent `pstack:<model>-<effort>`, which sets both in its frontmatter. List the ones the Agent tool shows. This plugin ships agents for `opus`, `fable`, and `sonnet` at each effort `low`, `medium`, `high`, `xhigh`, and `max`. Offer only combinations whose agent the Agent tool lists. A bare model runs at the session's own effort.

Also check for OpenAI's Codex CLI with `command -v codex && codex login status`. When both succeed, `codex:<model>:<effort>` is available for panel roles (arena runners, arena cross-judge pool, architect runners, interrogate reviewers). A Codex seat runs through `scripts/codex-seat.sh`, not a subagent. When Codex is missing or logged out, say so, and a configured Codex seat falls back to a `sonnet` subagent at run time.

### 2. Load current state

The default role-to-model mapping is the file shape shown in step 5 below. If `~/.claude/pstack-models.md` already exists, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from those defaults. A line whose role is not in step 5 is from a retired role. Drop it.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Use AskUserQuestion. Offer these three options with these exact labels, and name the current budget when the file records one.

- `balanced — opus xhigh judges, opus medium codes` (the defaults in step 5)
- `max — opus xhigh everywhere`
- `lean — sonnet judges, haiku codes`

**(b) Apply it.** Build the working table from the defaults in step 5, and on a re-run keep any role the user changed away from the defaults.

- `balanced` leaves the defaults as they are.
- `max` sets every single-model role to `opus:xhigh`. Panel lists keep their mix so reviewers still differ.
- `lean` sets `judgment and prose`, `hardest tasks`, and every synthesizer or explainer role to `sonnet`, every code and worker role to `haiku`, and every panel list to `sonnet, haiku`.

If a value's model is not in the detected set, use the next model down the ladder `opus` > `fable` > `sonnet` > `haiku` that is detected, drop its effort unless that combination also has an agent, and mark the role as changed. A Codex entry stays as configured. `inherit` does not change.

**(c) Show the roles and confirm.** Show every role with its value. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models, the shipped effort combinations, the Codex entry when available, and `inherit`. Use AskUserQuestion. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one seat runs per entry, alias entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena picks one value from it that differs from the parent's model when possible. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every model written must be in the detected set, every `<model>:<effort>` must have its `pstack:<model>-<effort>` agent listed, and a Codex entry needs Codex installed and logged in. `inherit` always passes. If a chosen value is not available, stop and ask again.

### 5. Write the file

Write `~/.claude/pstack-models.md` with a `# budget` line and one line per role, using the same labels poteto-mode uses. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# Values: a model (opus, sonnet, haiku, fable), <model>:<effort> for a shipped pstack:<model>-<effort> agent,
# codex:<model>:<effort> for a Codex CLI seat (panel roles only), or inherit (omit the Agent `model`).
# Alias entries in a panel list still count toward its fan-out.
# budget: balanced
feature, refactoring: opus:medium
bug-fix: opus:medium
perf-issue: opus:medium
hillclimb: opus:medium
judgment and prose: opus:xhigh
hardest tasks: opus:xhigh
how explorer: sonnet
how explainer: opus:xhigh
why investigators: sonnet
why synthesizer: opus:xhigh
reflect tooling: sonnet
reflect judgment, divergent, synthesizer: opus:xhigh
arena runners: opus:xhigh, fable:high, codex:astra:high
arena cross-judge pool: opus:xhigh, fable:high, codex:astra:high
swarm workers: sonnet
architect runners: opus:xhigh, fable:high, codex:astra:high
interrogate reviewers: opus:xhigh, fable:high, codex:astra:high
```

### 6. Confirm

Tell the user the file was written and that skills read it the next time they spawn a subagent. Re-running this skill updates it. Also tell them they can override any role for one run by naming it in the request, such as "interrogate with opus:max and codex:astra:xhigh".

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? Run /pstack:create-verification-skill and it will generate one." It is user-only, so you cannot start it yourself. On no, move on without pushing.
