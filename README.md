# <YOUR_NAME>'s Dotfiles

A minimal template for building intelligent dotfiles with automatic environment detection and package installation.

> **Powered by [chezmoi](https://chezmoi.io/) ❤️** — Leverages its templating engine and state management.

## 🚀 Setup Guide

### 0. Prerequisites

- Review [original implementation](https://github.com/DakEnviy/dots) for detailed examples and documentation
- Read [chezmoi basics](https://www.chezmoi.io/)
- Check the [go template docs](https://pkg.go.dev/text/template) and [sprig functions](https://masterminds.github.io/sprig/)

### 1. Clone Template

```bash
git clone https://github.com/DakEnviy/dots-template.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
git remote set-url origin <YOUR_REPO_URL>
```

### 2. Personalize Template

Replace placeholders with your information:

- `README.md`: Change `<YOUR_NAME>` to your name
- `bootstrap.sh`: Set `<YOUR_REPO_URL>` to your repository URL (e.g., `git@github.com:<username>/dotfiles.git`)
- `.chezmoi.yaml.tmpl`: Remove or uncomment example code if needed

### 3. Register Applications

Add applications to `.chezmoidata/apps.yaml`:

```yaml
- name: app-name
  desc: Brief description
  exec: binary-name        # Used for scanning system and as ID for the app
  conf: true               # Set to true if you provide config files for the app
  install:
    apt: package-name      # APT package
    brew: package-name     # Homebrew formula
    brew: cask "app"       # Homebrew cask
    cargo: crate-name      # Cargo crate
    script: 'command'      # Custom install script
    external: {}           # Chezmoi external source
```

**Installation methods:**

- **apt**: APT package install
- **brew**: Homebrew install. Values starting with `brew`/`cask` or multiline are passed as-is to [Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile), otherwise wrapped as `brew "package"`
- **cargo**: Installed via `cargo install`
- **script**: Custom shell command (runs once if package selected)
- **external**: Downloads binaries/archives via [chezmoi externals](https://www.chezmoi.io/reference/special-files/chezmoiexternal-format/) (GitHub releases, direct URLs)

**Selection logic (priority order):**

1. **System package manager** (apt for Debian-based, brew for macOS) — if available
2. **cargo** — if Rust toolchain installed
3. **script** — always available
4. **external** — always available

**Additional steps (modifiers with `!`):**

Use `!` suffix to add supplementary installation steps:
- **apt!/brew!**: Dependencies that must be installed before the main package
- **script!**: Additional script that runs after the main installation

**Why use this?** Some packages require system dependencies (e.g., `build-essential` for Rust compilation) or post-install setup (e.g., changing default shell). These steps execute regardless of which main method was selected.

**`conf` flag:** Set to `true` when you provide configuration files. This enables `.configure.<app>` variable in templates.

### 4. Add Configuration Files

**Template rules:**

1. **Always use templates**: Add `.tmpl` extension to enable conditional logic or use `chezmoi add -T <file>` to create a template file.

2. **Wrap in app check**:

   ```go
   {{ if .configure.app -}}
   # Your configuration here
   {{ end -}}
   ```

3. **Wrap integrations**:

   ```go
   {{ if and .configure.vim .configure.delta .binaries.delta -}}
   # Delta integration in Vim config
   {{ end -}}
   ```
   If config references another tool, check both `.configure` and `.binaries`.

4. **Check binary presence** only when missing binary would break at runtime:

   ```go
   {{ if and .configure.tmux .binaries.tmux -}}
   # Run-time command that requires tmux binary
   {{ end -}}
   ```

   **Note**: Don't check `.binaries` for config files themselves. If `tmux` binary doesn't exist, `~/.tmux.conf` won't break anything — it just won't be used.

5. **Use binary paths** when the binary might not be in PATH:

   ```go
   {{ .binaries.starship }} init fish | source
   ```

   Use `{{ .binaries.app }}` instead of just `app` in these cases:
   - **Chezmoi `run_*` scripts** — execute outside your configured shell environment
   - **Non-main shell execution** — e.g., bash script when your main shell is fish
   - **Early shell initialization** — before PATH is fully configured by your shell scripts

### 5. Customize `.chezmoi.yaml.tmpl` (Optional)

Add custom prompts for your configs:

**Best practices:**

- Store values in `data` section for template access
- Use `prompt*Once` to avoid re-asking same questions
- Use `unsafe` section for prompting empty variables (see commented example in file)

**Example:**

```go
{{- $myVar := dig "my" "var" "" . -}}
{{- if $configure.myapp -}}
{{-   $myVar = promptStringOnce . "unsafe.myVar" "Enter value" $myVar -}}
{{- else -}}
{{-   $myVar = "" -}}
{{- end -}}

data:
  my:
    var: {{ $myVar | quote }}
  unsafe:
    _: ""
    {{- with $myVar }}
    myVar: {{ . | quote }}
    {{- end }}
```
