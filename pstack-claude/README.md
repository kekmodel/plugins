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
| Models | grok / opus / gpt-sol mix | Claude models only. Defaults: `opus` for judgment, `sonnet` for code, `opus, fable, sonnet` for review panels |
| Budget | effort ladder (max to medium) | `balanced`, `max`, `lean` |
| Nested spawns | subagents spawn subagents (depth 3) | only the main thread spawns. Orchestrate has no sub-coordinators, and autopilot owners hand fan-out back to the root |
| Cloud workers | `environment: "cloud"` | background subagents, with `isolation: "worktree"` when they write |
| Sticky mode | `mode: true` frontmatter | poteto-mode says in its own text that it stays on for the conversation |
| `/goal` | the agent arms it | a `goal.md` file the audit tick re-reads. Claude Code's `/goal` exists, but only the user can run it, and its Stop hook would keep the root from idling between `/loop` ticks |
| PR forge | `gh` or Origin | `gh` only (GitHub MCP tools as a fallback) |
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

## Cross-model review is weaker here

`arena`, `architect`, `interrogate`, and `reflect` were built to pit different vendors' models against each other. With Claude models only, the panels mix `opus`, `fable`, and `sonnet`, and each reviewer still gets its own angle. That keeps reviewers independent, but it does not catch the blind spots one model family shares. If `fable` is not on your account, `setup-pstack` swaps it for the next model down.

## Not included

- `make-bot-ui`. It targets Cursor Automations webhooks.
- The benny automation pack. It targets Cursor Automations and Slack.
- The Cursor setup guide under `pstack/docs/guide/`. Its concepts still apply, but its steps are Cursor-specific.

## Requirements

- `gh` for every PR playbook (babysit, shipping, opening a PR, autopilot, orchestrate).
- [Bun](https://bun.sh) for `scripts/orch` and `scripts/watch-pr`. They install their own dependencies on first run.
- MCP servers are optional. `/pstack:why` uses whichever ones are connected (Slack, Linear, Notion, Sentry, Datadog, and so on) and falls back to git history.

## License

MIT, same as upstream. See [LICENSE](./LICENSE).
