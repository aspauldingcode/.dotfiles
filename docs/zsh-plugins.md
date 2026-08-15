# Zsh & Starship

Declarative via Home Manager in [`modules/shell-config.nix`](../modules/shell-config.nix). No plugin managers.

## Zsh

- **autosuggestions** — gray history hint; `→` accepts
- **syntax-highlighting** — green/red as you type
- **completions** — HM `compinit` + `zsh-completions` / `nix-zsh-completions`
- **history-substring-search** — `↑` / `↓` match the current word
- **fzf** — `Ctrl+R` history, `Ctrl+T` files, `Alt+C` directories (`fd`)
- **fzf-tab** — fuzzy `<Tab>` completion
- **zoxide** — `cd` is zoxide
- **zsh-vi-mode** — vim editing; `Esc Esc` toggles `sudo`
- **direnv** + **nix-direnv** — auto-load flakes
- **yazi** — `y` cd-wrapper (`builtin cd` so zoxide stays happy)

Aliases: `l` (`eza -a`), `tree` (`eza --tree`), `nhos` (`dendritic-os-switch`).

## Starship

Prompt is only directory, git, nix-shell, and the character. No language/version modules.

```text
format = "$directory$git_branch$git_status$nix_shell$character"
```

`STARSHIP_LOG=error` so warnings cannot paint the TTY mid-precmd.

## Other CLI

`bat`, `eza`, `comma`, `manix`, `btop`, `htop`.
