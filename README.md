# smith-case
A portable case of (dev) tools, dotfiles and scripts for quickly setting up my macOS environment

```
% chmod +x bootstrap.zsh
% ./bootstrap.zsh
```

## Agent configuration

`bootstrap.zsh` links shared agent configuration from this repository:

- `.codex/AGENTS.md` -> `~/.codex/AGENTS.md` for Codex global guidance
- `.claude/CLAUDE.md` -> `~/.claude/CLAUDE.md` for Claude Code; it imports the Codex guidance
- `.agents/skills/*` -> `~/.agents/skills/*` for Codex user skills
