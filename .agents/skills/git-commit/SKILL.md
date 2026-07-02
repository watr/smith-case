---
name: git-commit
description: "Use when preparing git commits, staging changes, reviewing staged diffs, splitting commits, writing commit messages, or checking AI agent attribution in commit messages."
---

# Git commit workflow

Use this skill whenever you prepare, review, create, or suggest git commits.

This skill covers:

- Reviewing the working tree
- Selecting files or hunks to stage
- Splitting unrelated changes into separate commits
- Writing commit messages
- Checking whether AI agent attribution should be included
- Running final pre-commit checks when appropriate

## Commit preparation

Before creating a commit:

1. Inspect the working tree.
2. Review the relevant diffs.
3. Identify the logical purpose of each change.
4. Stage only the files or hunks that belong in the current commit.
5. Keep each commit focused and reviewable.

Do not use:

```sh
git add .
```

Prefer explicit staging, such as:

```sh
git add path/to/file
git add -p
```

If the working tree contains unrelated changes, split them into separate commits.

If generated files, lockfiles, snapshots, or formatting-only changes are included, verify that they are intentional.

## Commit message format

Use this format:

```text
<type>(<scope>): <summary>
```

Allowed types:

- `feat`
- `fix`
- `refactor`
- `test`
- `docs`
- `chore`

Rules:

- Use imperative mood.
- Keep the summary under 72 characters.
- Do not end the summary with a period.
- Include a scope when the affected area is clear.
- Keep the subject line specific to the staged change.
- Do not mention implementation details that are not relevant to the commit history.

Examples:

```text
feat(auth): add session refresh handling
fix(api): handle missing user id
docs(readme): document local setup
refactor(worker): simplify retry scheduling
test(auth): cover expired token flow
chore(deps): update lockfile
```

## Commit body

Use a commit body only when it adds useful context.

Good reasons to add a body:

- Explain why the change was made.
- Document a non-obvious tradeoff.
- Call out migration or compatibility concerns.
- Explain risk, rollback, or operational impact.

Do not use the body to restate the summary.

## AI agent attribution

Do not add AI agent attribution to commit messages by default.

Avoid adding:

- Agent names
- AI assistant names
- Tool names
- `Generated-by:` trailers
- `AI-assisted-by:` trailers
- `Co-authored-by:` trailers for AI agents
- Phrases such as “generated with”, “created by”, or “assisted by” followed by a specific agent name

Rationale:

A commit may include edits from multiple agents, tools, scripts, programs, formatters, and manual work. Naming only the agent used during the commit step can misrepresent how the final change was actually produced.

Only include a specific agent name when there is an explicit reason to do so, such as:

- The user explicitly requests it.
- The repository policy requires it.
- The commit is specifically about output from that agent.
- The agent identity is materially relevant to the change history.
- Omitting the attribution would be more misleading than including it.

When in doubt, omit AI agent attribution.

## Final check before committing

Before running `git commit`, verify:

- The staged diff matches the intended change.
- No unrelated files are staged.
- The commit is appropriately scoped.
- The commit message follows the required format.
- The summary is concise, imperative, and under 72 characters.
- No unnecessary AI agent attribution is included.
- Any generated files or lockfiles are intentional.
- Any available relevant tests or checks have been considered.

If the user asks to commit and there are multiple logical changes, propose or create separate commits rather than combining them into one broad commit.
