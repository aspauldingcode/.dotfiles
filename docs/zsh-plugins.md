# Zsh Plugins & Shell Extensions

Curated set of zsh plugins and CLI tools integrated into the Dendritic Nix configuration. All plugins are installed declaratively via Nix (home-manager modules or nixpkgs) — no external plugin managers required.

> **Config location:** [`modules/shell.nix`](../modules/shell.nix)

---

## Core Productivity & UX

### zsh-autosuggestions _(pre-existing)_

Fish-like inline autosuggestions as you type, drawn from command history.

- Suggestions appear in gray — press `→` or `End` to accept.
- **Package:** `programs.zsh.autosuggestion.enable`

### zsh-syntax-highlighting _(pre-existing)_

Real-time syntax highlighting in the terminal. Valid commands turn green, errors turn red.

- **Package:** `programs.zsh.syntaxHighlighting.enable`

### zsh-completions _(pre-existing)_

Additional completion definitions for common tools not covered by default zsh.

- **Package:** `pkgs.zsh-completions`

### zsh-history-substring-search

Search history by **substring** rather than prefix. Much more powerful than default `up-arrow` behavior.

- **Keybindings:**
  - `↑` / `↓` — search history for commands containing the current input
  - Type `git co`, press `↑` → finds `git commit`, `git checkout`, etc.
- **Package:** `programs.zsh.historySubstringSearch.enable`

### zsh-you-should-use

Reminds you when an alias exists for a command you just typed manually.

```
$ git status
Found existing alias for "git status". You should use: "gst"
```

- Trains muscle memory over time. Zero friction — just prints a reminder.
- **Package:** `pkgs.zsh-you-should-use` (sourced via `initContent`)

### sudo (ESC ESC)

Double-tap `Escape` to prepend `sudo` to the current or last command. Simple, indispensable.

- **Implementation:** Custom zsh widget in `initContent`

### colored-man-pages

Adds color to `man` pages using `LESS_TERMCAP` environment variables. Zero performance cost.

- **Implementation:** Environment variables in `initContent`

### extract

Smart archive extraction — `extract foo.tar.gz` handles `.tar.gz`, `.zip`, `.7z`, `.rar`, `.bz2`, `.xz`, and more.

```bash
extract archive.tar.xz    # Just works, no flags to remember
```

- **Implementation:** Shell function in `initContent`

---

## Fuzzy Finding & Navigation

### fzf

General-purpose command-line fuzzy finder. Powers `Ctrl+R` history search, file search, and more.

- **Keybindings:**
  - `Ctrl+R` — fuzzy search command history
  - `Ctrl+T` — fuzzy find files in current directory
  - `Alt+C` — fuzzy `cd` into subdirectories
- **Package:** `programs.fzf.enable` with `enableZshIntegration`

### fzf-tab

Replaces zsh's default tab-completion menu with fzf. Every `<Tab>` becomes a fuzzy search.

```bash
cd /etc/<Tab>        # Fuzzy-filter all dirs under /etc
git checkout <Tab>   # Fuzzy-filter branches
kill <Tab>           # Fuzzy-filter running processes
```

- **Package:** `pkgs.zsh-fzf-tab` (sourced via `initContent`)

### zoxide

Smarter `cd` that learns your most-used directories. Replaces `cd` with `z`.

```bash
z darwin       # Jumps to /etc/nix-darwin (if visited before)
z mod shell    # Jumps to /etc/nix-darwin/modules/shell.nix dir
zi             # Interactive fuzzy directory picker
```

- **Package:** `programs.zoxide.enable` with `enableZshIntegration`

---

## Git Enhancements

### forgit

Interactive git wrapper powered by fzf. Makes git operations browsable and visual.

```bash
forgit::log     # or gl  — interactive git log with diff preview
forgit::diff    # or gd  — interactive diff viewer
forgit::add     # or ga  — interactive staging
forgit::stash   # interactive stash browser
```

- **Package:** `pkgs.zsh-forgit` (sourced via `initContent`)

---

## Vim Integration

### zsh-vi-mode

Full vim-mode editing for the zsh command line. Consistent with Neovim muscle memory.

- **Modes:** Normal, Insert, Visual, Replace — just like Vim.
- `Escape` enters Normal mode, `i`/`a` return to Insert.
- Visual block selection, text objects (`ciw`, `da"`, etc.) all work.
- Cursor shape changes to indicate mode (beam = insert, block = normal).
- **Package:** `pkgs.zsh-vi-mode` (sourced via `initContent`)

---

## Developer Experience (CLI Tools)

### bat

`cat` replacement with syntax highlighting, line numbers, and git integration.

```bash
bat shell.nix            # Syntax-highlighted file viewing
bat --diff shell.nix     # Shows git diff inline
```

- Aliased as `cat` → `bat` for seamless adoption.
- **Package:** `programs.bat.enable`

---

## Nix-Specific Integrations

### direnv + nix-direnv

Automatically loads/unloads `nix develop` shell environments when you `cd` into a project with a `flake.nix`.

```bash
cd ~/myproject/    # devShell activates automatically
cd ~               # devShell deactivates
```

- Uses cached evaluations via `nix-direnv` — fast re-entry on subsequent visits.
- Requires a `.envrc` file in the project root containing `use flake`.
- **Package:** `programs.direnv.enable` + `programs.direnv.nix-direnv.enable`

### any-nix-shell

Keeps you in **zsh** when entering `nix-shell` or `nix develop`. Without this, Nix drops you into bash.

- **Package:** `pkgs.any-nix-shell` (sourced via `initContent`)

### comma (`,`)

Run any program from nixpkgs **without installing it**.

```bash
, cowsay "hello"     # Downloads, runs cowsay, doesn't persist
, httpie GET api.io  # One-off HTTP request
```

- Powered by `nix-index` — needs an initial index build (runs automatically).
- **Package:** `pkgs.comma`

### nix-index + command-not-found

When you type a command that isn't installed, suggests which Nix package provides it.

```
$ rg
nix-index: rg is provided by nixpkgs#ripgrep
```

- **Package:** `programs.nix-index.enable` with `enableZshIntegration`

### nix-zsh-completions

Tab completions for all `nix` CLI subcommands (`nix build`, `nix develop`, `nix flake show`, etc.).

- **Package:** `pkgs.nix-zsh-completions`

### manix

Fast CLI documentation search for NixOS / home-manager options.

```bash
manix "programs.zsh"           # Search all option docs
manix "services.openssh"       # Find SSH service options
```

- **Package:** `pkgs.manix`

---

## Prompt

### Starship _(pre-existing)_

Cross-shell prompt with git status, nix-shell indicator, language versions, and more. Already configured with performance optimizations.

- **Package:** `programs.starship.enable`

---

## File Management

### Yazi _(pre-existing)_

Terminal file manager with image preview support. Invoked via `y` wrapper
(cd into last dir on `q`; `Q` quits without changing cwd).

- **Package:** `programs.yazi.enable` with `shellWrapperName = "y"`
- **Requires:** `programs.zsh.enable = true` (integration only writes into HM-managed zshrc)
- **Note:** `home.stateVersion < 26.05` defaults the wrapper name to `yy` — we pin `y`
- **Note:** Wrapper uses `builtin cd` so it works with `zoxide` as `cd`

---

## System Monitoring

### btop _(pre-existing)_

Resource monitor themed by Stylix.

- **Package:** `programs.btop.enable`

### htop _(pre-existing)_

Classic process viewer.

- **Package:** `programs.htop.enable`
