# Changelog

## Unreleased

* Renamed the project to leanin.
* Made `LEANIN_*` variables primary and kept `ARCHBOOT_*` compatibility aliases.
* Moved new logs to `~/.local/state/leanin/logs` without removing old logs.
* Polished runtime output with clearer stage names, summaries, and diagnostics.
* Improved doctor, plan, and dry-run formatting.
* Added output regression checks.
* Refined the README into a portfolio-style project page.
* Improved the local SVG project banner.
* Added stricter README structure checks.
* Redesigned the README as a portfolio-style English project page.
* Added a local SVG project banner.
* Moved verbose documentation out of the main README.
* Added stricter documentation checks.
* Fixed SSH key generation prompt handling when running through `curl | bash`.
* Added Sober Roblox launcher as a default Flatpak app.
* Added Flatpak games category.
* Final bug hunt and output cleanup.
* Reordered installer steps for clearer source, SSH and GitHub flow.
* Removed the empty final integration stage.
* Expanded regression coverage for output, prompts and edge cases.
* Fixed GitHub SSH prompt ordering so key title is only requested when a key will actually be registered.
* Fixed confirmation prompts when running through `curl | bash` by reading from `/dev/tty`.
* Added `--doctor` for quick local diagnostics.
* Kept the personal fast main-based installer flow.
* Added confirmation prompts before reconfiguring existing Git, SSH, GitHub, Codex and service state.
* `--yes` keeps safe defaults and does not force destructive reconfiguration.
* Fixed sudo command resolution when the installer validation helper is loaded.
* Hardened app/service parsing, SSH backup recovery and bootstrap minimum-PATH handling.
* Expanded regression coverage for bootstrap failures, Worker behavior, prompts and side effects.
* Initial technical hardening.
* Expanded structural, argument, security and bootstrap checks.
* Removed unused internal state.
* Strengthened argument and bootstrap validation.
* Hardened remote repository, branch, tarball and extraction validation.
* Added log redaction and restrictive log permissions.
* Added focused troubleshooting documentation and clearer failure diagnostics.

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
