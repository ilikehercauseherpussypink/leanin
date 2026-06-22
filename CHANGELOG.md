# Changelog

## Unreleased

* Rebuilt GitHub SSH setup around `gh api user/keys` with supervised `/dev/tty` authentication, capability revalidation, and guarded remote-key cleanup.
* Kept SSH, Git, Codex, package, and service changes opt-in when existing state differs; `--yes` retains safe defaults.
* Added read-only `--doctor`, `--plan`, and dry-run modes, plus deterministic CI behavior through `LEANIN_CI` and the `ARCHBOOT_CI` compatibility alias.
* Hardened remote bootstrap validation, log redaction, and `curl | bash` TTY handling.
* Simplified installer stages around a single package phase and removed unused modules and obsolete compatibility paths.
* Expanded deterministic regression coverage for parser safety, bootstrap, local SSH, GitHub API, services, output, and Worker behavior.
* Refined the English documentation and portfolio-oriented README around the public `shelies.org` installer.

## v0.1.1

* Release tag aligned with the current published state.
* Kept the published v0.1.0 tag intact without rewriting history.
* Includes CI, installer control flags, plan/version modes, `LEANIN_CI`, updated documentation and public checks through `shelies.org`.

## 0.1.0

* Added modular Arch Linux bootstrap with clean output and audit-first execution.
* Added short-domain installation through a Cloudflare Worker.
* Added editable application lists with pacman, Flatpak/Flathub and AUR support.
* Added the EasyEffects audio category and modular system/user service activation.
* Added Mullvad package conflict protection and daemon service management.
* Added Codex CLI installation with an isolated `~/.codex` npm prefix.
* Added Git identity, SSH key and GitHub CLI integration with automatic key registration.
* Added honest dry-run behavior, structured logs and comprehensive local checks.
* Added GitHub Actions checks for Bash, ShellCheck and the Cloudflare Worker.
* Added `--version` and a read-only `--plan` mode.
* Added granular `--no-*` installer control flags.
* Added `--yes` with non-interactive safe defaults.
* Added a portable, dry-run-only CI mode.
