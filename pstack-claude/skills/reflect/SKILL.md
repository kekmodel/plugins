---
name: reflect
description: Spawn three parallel review subagents over the active transcript, surface learnings, and route each to a concrete edit on an existing skill. Use when the user says reflect.
disable-model-invocation: true
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

## When to invoke

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## Process

### 1. Locate the active transcript

The parent finds its own transcript file before fanning out. It lives in this project's transcript directory, `~/.claude/projects/<slug>/`, where `<slug>` is the working directory with every character other than a letter or digit turned into `-` (`/home/you/my_app` becomes `-home-you-my-app`). Very long paths are cut short with a hash suffix, so if the directory is missing, find it with `ls ~/.claude/projects | grep <repo-name>`. Use that path. Do not glob across `~/.claude/projects/*/`. That crosses project boundaries and reads private chats from unrelated projects.

```bash
ls ~/.claude/projects/<slug>/${CLAUDE_SESSION_ID}.jsonl
```

This session's ID is `${CLAUDE_SESSION_ID}`. Its subagents sit under `${CLAUDE_SESSION_ID}/subagents/`.

Confirm it by finding the first line whose `type` is `user` and checking that its `message.content` contains the conversation's opening user prompt. If no path resolves, write a tight digest of the session and pass that instead.

### 2. Spawn three reviewers in parallel

One message, three `Agent` calls, `subagent_type: general-purpose` (or `pstack:<model>-<effort>` when the value pins an effort), with `model` set as below. Both keep MCP access, which reviewers need for context lookups (tickets, chat threads, observability traces referenced in the transcript).

Each reviewer and the synthesizer name a role line in `~/.claude/pstack-models.md` and a default. Set `model` to that line's value, or to the default if the file or the line is missing. Leave `model` unset when the value is `inherit`. If the Agent tool rejects a value, use the default and say so. If it rejects the default too, leave `model` unset and say so. A value of the form `<model>:<effort>`, such as `opus:xhigh`, means: spawn `subagent_type: pstack:<model>-<effort>` and leave `model` unset, since that agent pins both. If the Agent tool does not list that agent, spawn the usual type with `model: <model>` and say the effort was not applied. When the user names a model, effort, or panel for this run (for example "interrogate with opus:max and codex:astra:xhigh"), use it for this run in place of the config line and the default.

| Lens | Role line | Default `model` | Prompt template |
|---|---|---|---|
| Judgment | `reflect judgment, divergent, synthesizer` | `opus:xhigh` | `references/judgment-reviewer.md` |
| Tooling | `reflect tooling` | `fable:high` | `references/tooling-reviewer.md` |
| Divergent | `reflect judgment, divergent, synthesizer` | `opus:xhigh` | `references/divergent-reviewer.md` |

Pass each template verbatim, substituting the transcript path or digest where marked. Reviewers return findings in the `Agent` response body.

### 3. Synthesize

One `Agent` call, `subagent_type: general-purpose` (or `pstack:<model>-<effort>` when the value pins an effort), with `model` from the `reflect judgment, divergent, synthesizer` line (default `opus:xhigh`). The synthesizer's quality check includes spot-verifying citations, which can require MCP access. Never use a tool-restricted type. Use `references/synthesizer.md` verbatim, with each reviewer's full output inlined where marked. The synthesizer returns a structured Accepted / Rejected / Backlog list.

### 4. Structural enforcement check

Sanity-check the synthesizer's Accepted list. For any item that would be enforced more reliably by a lint rule, script, metadata flag, or runtime check, move it from Accepted to Backlog. See the **encode-lessons-in-structure** principle skill.

### 5. Apply

Before applying any Accepted edit, present the synthesizer's full Accepted/Rejected/Backlog output to the user and wait for explicit approval. The user picks which subset to apply and may redirect routings. Skill changes affect every future agent in the org. Do not auto-apply.

Backlog items file to whatever devex / backlog tracker your team uses automatically. Only the Accepted list waits for approval.

For each approved Accepted item, follow the Routing field exactly:

- Trivial existing-skill edit (a one-line bullet, a tightened sentence, a stale fact corrected): parent does directly.
- Substantive existing-skill edit (a new section, a new pattern table, more than ~10 lines): hand to Anthropic's `skill-creator` skill when installed and run its draft / test / iterate loop. Without it, edit directly and re-read the result against the skill's own rules.
- `tune description: <skill path>` (the skill exists but didn't trigger when it should have): hand to `skill-creator` and run its description-optimization loop.
- `new skill via skill-creator: <kebab-name>`: hand creation to `skill-creator`. Do not invent the shape ad hoc.

If your environment ships a SKILL.md validator, run it on every touched skill before declaring done. Skip this step if it doesn't.

### 6. Summarize for the user

Short list, no preamble:

- Edits applied: `<skill path>`. What changed, one line each.
- New skills created: `<skill path>`. One line each (rare).
- Backlog filed to the devex tracker: `<issue title>` (`<tags>`). One line each.
- Dropped: one line per rejected finding + reason from the synthesizer.
