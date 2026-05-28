# SHIRUBE(標)

SHIRUBE is an all-in-one fuzzy finder for `zsh` and `bash` powered by `fzf`.
Press shortcut keys in your shell to search and select:

| Key | Action |
|-----|--------|
| `Ctrl+x g` | Select a ghq-managed Git repository and jump to it |
| `Ctrl+x w` | Select a git worktree and jump to it (`Ctrl+n`: new / `Ctrl+r`: delete) |
| `Ctrl+x b` | Select a git branch and check it out (`Ctrl+n`: new / `Ctrl+r`: delete) |
| `Ctrl+x p` | Select a pull request from gh pr list and check it out (`Ctrl+o`: open in browser) |
| `Ctrl+x i` | Select an issue from gh issue list and open it in browser |
| `Ctrl+r` | Select a command from history and execute it |

Inspired by [anyframe](https://github.com/mollifier/anyframe).

## Requirements

- **Required**: [fzf](https://github.com/junegunn/fzf)
- **Optional**: Each feature requires its corresponding tool
  - `ghq` - Repository management (`Ctrl+x g`)
  - `git` - Branch and worktree operations (`Ctrl+x b`, `Ctrl+x w`)
  - `gh` - GitHub CLI (`Ctrl+x p`, `Ctrl+x i`)

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

## Development

### Running tests

Tests use [bats-core](https://github.com/bats-core/bats-core). Fetch submodules on first use:

```sh
git submodule update --init --recursive
./test/bats/bin/bats test/
```

### Linting

Linting uses [shellcheck](https://github.com/koalaman/shellcheck):

```sh
shellcheck shirube.sh shirube.bash shirube.zsh shirube.plugin.bash shirube.plugin.zsh
```

### Formatting

Formatting uses [shfmt](https://github.com/mvdan/sh). `shirube.sh` is excluded because it contains zsh-specific syntax that shfmt cannot parse.

```sh
# Check
shfmt -d shirube.bash shirube.zsh shirube.plugin.bash shirube.plugin.zsh

# Apply
shfmt -w shirube.bash shirube.zsh shirube.plugin.bash shirube.plugin.zsh
```

## License

MIT
