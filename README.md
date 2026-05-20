# SHIRUBE(標)

SHIRUBE is an all-in-one fuzzy finder for `zsh` and `bash` powered by `fzf`.
Press shortcut keys in your shell to search and select:

| Key | Action |
|-----|--------|
| `Ctrl+x Ctrl+g` | Select a ghq-managed Git repository and jump to it |
| `Ctrl+x Ctrl+w` | Select a git worktree and jump to it |
| `Ctrl+x Ctrl+b` | Select a git branch and check it out |
| `Ctrl+x Ctrl+p` | Select a pull request from gh pr list and check it out |
| `Ctrl+r` | Select a command from history and execute it |

Inspired by [anyframe](https://github.com/mollifier/anyframe).

## Requirements

- **Required**: [fzf](https://github.com/junegunn/fzf)
- **Optional**: Each feature requires its corresponding tool
  - `ghq` - Repository management (`Ctrl+x Ctrl+g`)
  - `git` - Branch / worktree operations (`Ctrl+x Ctrl+w`, `Ctrl+x Ctrl+b`)
  - `gh` - GitHub CLI (`Ctrl+x Ctrl+p`)

## Installation

### zinit (zsh)

```zsh
zinit light yuuu/shirube
```

### bash-it (bash)

```bash
git clone https://github.com/yuuu/shirube.git "${BASH_IT}/custom/shirube"
```

### Manual

**zsh** - Add to `~/.zshrc`:

```zsh
source /path/to/shirube/shirube.zsh
```

**bash** - Add to `~/.bashrc`:

```bash
source /path/to/shirube/shirube.bash
```

## License

MIT
