# pstack for Claude Code

A Claude Code port of [pstack](../pstack/), poteto's Cursor plugin for rigorous agent work. The skills, playbooks, and principles are the same. The tool names, model setup, and paths are rewritten for Claude Code.

Ported from `pstack` 0.15.5 at commit `2eb7ed4`. To pull upstream changes later, diff `pstack/` from that commit and apply what still fits.

## Install

```
/plugin marketplace add kekmodel/plugins
/plugin install pstack@kekmodel-plugins
```

Then:

1. Run `/pstack:setup-pstack` to pick a budget and the model for each role. It writes `~/.claude/pstack-models.md`. Skip it and every skill uses the defaults below.
2. Start a task with `/pstack:poteto-mode <what you want>`. It picks a playbook and calls the other skills as its steps need them.

Every skill can also be called directly, for example `/pstack:how`, `/pstack:interrogate`, or `/pstack:unslop`. See the [upstream README](../pstack/README.md) for what each one does.

## What changed from the Cursor version

| Area | Cursor pstack | This port |
|---|---|---|
| Subagents | `Task` tool, `generalPurpose`, `readonly` | `Agent` tool, `general-purpose`, a "do not edit files" line in the prompt |
| Questions | `AskQuestion` | `AskUserQuestion` |
| Model config | `~/.cursor/rules/pstack-models.mdc` | `~/.claude/pstack-models.md` |
| Models | grok / opus / gpt-sol mix | `opus:xhigh` for judgment, `opus:medium` for playbook code delegates, `sonnet` for explorers, investigators, and swarm workers, and review panels of `opus:xhigh`, `fable:high`, and a Codex CLI seat (`codex:astra:high`) |
| Effort | an effort token in the model slug | `<model>:<effort>` runs on a shipped `pstack:<model>-<effort>` agent that pins both in its frontmatter. Budgets are `balanced`, `max`, `lean` |
| Nested spawns | subagents spawn subagents (depth 3) | only the main thread spawns. Orchestrate has no sub-coordinators, and autopilot owners hand fan-out back to the root |
| Cloud workers | `environment: "cloud"` | background subagents, with `isolation: "worktree"` when they write |
| Sticky mode | `mode: true` frontmatter | poteto-mode says in its own text that it stays on for the conversation |
| `/goal` | the agent arms it | a `goal.md` file the audit tick re-reads. Claude Code's `/goal` exists, but only the user can run it, and its Stop hook would keep the root from idling between `/loop` ticks |
| PR forge | `gh` or Origin | `gh` (GitHub MCP tools as a fallback). Orchestrate still uses `gt` for its stack frontier |
| `deslop` | `cursor-team-kit` | Claude Code's built-in `/simplify` |
| `control-ui`, `control-cli` | `cursor-team-kit` | the project's `verify-*` skill, else Claude Code's `run` skill, else Playwright or a plain shell run |
| `create-skill` | Cursor built-in | Anthropic's `skill-creator` skill when installed |
| Transcripts | `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.claude/projects/<slug>/<session-id>.jsonl` |
| Agent names | `Comment Sicko` | `comment-sicko` (listed as `pstack:comment-sicko`) |

## Which skills Claude can call

Upstream marks every skill except `setup-pstack` as `disable-model-invocation: true`. In Claude Code that flag also blocks the Skill tool, and the harness then tells Claude not to follow the skill by other means. That would stop `poteto-mode` from routing to `how`, `architect`, the principles, and the rest.

So this port splits them:

- **User-only** (`disable-model-invocation: true`): `poteto-mode`, `setup-pstack`, `automate-me`, `recall`, `reflect`, `teach`, `bro`, `blast-radius`, `create-verification-skill`, `maintain-verification-skill`.
- **Routed** (Claude can load them): `how`, `why`, `architect`, `arena`, `swarm`, `interrogate`, `unslop`, `no-comments`, `technical-writing`, `tdd`, `show-me-your-work`, `figure-it-out`, `typescript-best-practices`, and the 23 principles. Each description ends with "Only when /poteto-mode is active, another pstack skill routes here, or the user asks for it by name", so they stay quiet in ordinary chats.

## Cross-model review with Codex

`arena`, `architect`, and `interrogate` pit different models against each other. A Claude subagent can only run Claude models, so the third seat runs OpenAI's Codex CLI through `scripts/codex-seat.sh`. Codex starts in the repo root and reads the codebase itself. Review seats run in a read-only sandbox. An arena runner may write only inside its own candidate directory.

The seat needs the Codex CLI (`npm install -g @openai/codex`) and a login (`codex login`). Without them, when a run fails, or when it runs past `CODEX_SEAT_TIMEOUT` (default 1200 seconds), that seat falls back to a `sonnet` subagent and the skill says so. `astra` is the default Codex model. If your account does not have it, set another with `/pstack:setup-pstack`.

The rules for every role value, Codex seats included, live in one place: [`references/model-values.md`](references/model-values.md).

## Effort agents

The plugin ships one agent per model and effort for `opus`, `fable`, and `sonnet` at `low`, `medium`, `high`, `xhigh`, and `max`, named `<model>-<effort>`. Each pins both in its frontmatter, since the Agent tool cannot set effort per call. Claude Code runs every pair without error, but a model may not honor an effort it does not support. To add a model, run `scripts/gen-effort-agents.sh <model>`.

## Changing the models

The values above are defaults. Change them for good with `/pstack:setup-pstack`, or by editing `~/.claude/pstack-models.md`. Change them for one run by naming them in the request, for example `/pstack:interrogate review this PR with opus:max, fable:xhigh, and codex:astra:xhigh`.

## Not included

- `make-bot-ui`. It targets Cursor Automations webhooks.
- The benny automation pack. It targets Cursor Automations and Slack.
- The Cursor setup guide under `pstack/docs/guide/`. Its concepts still apply, but its steps are Cursor-specific.

## Requirements

- `gh` for every PR playbook (babysit, shipping, opening a PR, autopilot, orchestrate).
- [Bun](https://bun.sh) for `scripts/orch` and `scripts/watch-pr`. They install their own dependencies on first run.
- [Graphite](https://graphite.dev) `gt` for Orchestrate only. `orch frontier set` reads the stack from `gt info`. The other PR playbooks never need it.
- The Codex CLI is optional. Without it, the Codex panel seat runs as a `sonnet` subagent.
- MCP servers are optional. `/pstack:why` uses whichever ones are connected (Slack, Linear, Notion, Sentry, Datadog, and so on) and falls back to git history.

## License

MIT, same as upstream. See [LICENSE](./LICENSE).
