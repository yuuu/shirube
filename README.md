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

If you pause after pressing `Ctrl+x`, a hint listing the available keys is shown (below the command line in zsh, in place of it in bash). Press one of the keys to continue, or `Esc` to cancel. Other `Ctrl+x` bindings (e.g. `Ctrl+x Ctrl+e`) keep working as before.

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

## Configuration

Each shortcut is a module that can be turned on or off in `~/.config/shirube/config` (or `$XDG_CONFIG_HOME/shirube/config`; set `SHIRUBE_CONFIG` to use another path). Write one `<module> = on|off` per line; modules not mentioned stay enabled.

```ini
# ~/.config/shirube/config
history = off   # keep the shell's own Ctrl+r
issue = off
```

| Module | Key |
|--------|-----|
| `ghq` | `Ctrl+x g` |
| `worktree` | `Ctrl+x w` |
| `branch` | `Ctrl+x b` |
| `pr` | `Ctrl+x p` |
| `issue` | `Ctrl+x i` |
| `history` | `Ctrl+r` |

`true`/`yes`/`1` and `false`/`no`/`0` are accepted as well. Disabled modules are not loaded and leave their keys untouched; the `Ctrl+x` hint lists only the enabled ones, and when none of the `Ctrl+x` modules is enabled, `Ctrl+x` itself is left alone. The config is read when SHIRUBE is loaded, so restart the shell after editing it.

## Development

### Layout

- `shirube.sh` - Core shared by bash and zsh: config loading, module loading, key binding and the `Ctrl+x` hint
- `modules/<name>.sh` - One file per shortcut, also shared by bash and zsh. A module defines `__shirube_<name>_command`, which runs the fzf selection and prints the resulting command line, and registers its key with `__shirube_register <name> <key> <mode>`. The core takes care of running the command in each shell (see the comment on `__shirube_register` for the modes)
- `shirube.bash`, `shirube.zsh`, `shirube.plugin.*` - Entry points for each shell and plugin manager

To add a module, create `modules/<name>.sh` and add `<name>` to `__shirube_modules` in `shirube.sh`.

### Running tests

Tests use [bats-core](https://github.com/bats-core/bats-core). Fetch submodules on first use:

```sh
git submodule update --init --recursive
./test/bats/bin/bats test/
```

### Linting

Linting uses [shellcheck](https://github.com/koalaman/shellcheck):

```sh
shellcheck shirube.sh shirube.bash shirube.zsh shirube.plugin.bash shirube.plugin.zsh modules/*.sh
```

### Formatting

Formatting uses [shfmt](https://github.com/mvdan/sh). `shirube.sh` is excluded because it contains zsh-specific syntax that shfmt cannot parse, and `modules/*.sh` follow the same style as `shirube.sh`.

```sh
# Check
shfmt -d shirube.bash shirube.zsh shirube.plugin.bash shirube.plugin.zsh

# Apply
shfmt -w shirube.bash shirube.zsh shirube.plugin.bash shirube.plugin.zsh
```

## License

MIT
