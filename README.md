# SHIRUBE(標)

SHIRUBE is an all-in-one fuzzy finder for `zsh` and `bash` powered by `fzf`.
Press shortcut keys in your shell to search and select:

| Key | Action |
|-----|--------|
| `Ctrl+x g` | Select a ghq-managed Git repository and jump to it |
| `Ctrl+x w` | Select a git worktree and jump to it (`Ctrl+n`: new / `Ctrl+r`: delete) |
| `Ctrl+x b` | Select a git branch and check it out (`Ctrl+n`: new / `Ctrl+r`: delete) |
| `Ctrl+x p` | Select a pull request from gh pr list and check it out |
| `Ctrl+r` | Select a command from history and execute it |

Inspired by [anyframe](https://github.com/mollifier/anyframe).

## Requirements

- **Required**: [fzf](https://github.com/junegunn/fzf)
- **Optional**: Each feature requires its corresponding tool
  - `ghq` - Repository management (`Ctrl+x g`)
  - `git` - Branch operations (`Ctrl+x b`)
  - [git-wt](https://github.com/k1LoW/git-wt) - Worktree operations (`Ctrl+x w`). Shell integration is required:
    ```zsh
    # zsh
    eval "$(git wt --init zsh)"
    # bash
    eval "$(git wt --init bash)"
    ```
  - `gh` - GitHub CLI (`Ctrl+x p`)

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
