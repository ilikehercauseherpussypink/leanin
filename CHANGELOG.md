# Changelog

## Unreleased

* Hardened GitHub CLI SSH-key authentication: fresh login requests `admin:public_key`, existing sessions can upgrade the scope, and both flows recheck SSH-key management before registration.
* Made GitHub device/browser authentication explicit, terminal-bound, and time-bounded, with accurate manual fallback guidance.
* Kept GitHub SSH summaries and tests honest when manual registration remains pending.
* Expanded regression coverage for GitHub auth, SSH-key registration, clipboard outcomes, and read-only modes.
* Made `--help` a true early exit and made dry-run summaries explicitly successful instead of reporting pending manual setup.
* Bound `ssh-add` passphrase prompts to `/dev/tty`, skipped agent mutation in safe modes, and removed forced SSH-backup restoration.
* Detect GitHub CLI clipboard support before requesting it, avoiding duplicate device-code authentication attempts.
* Rebuilt GitHub SSH setup around `gh api user/keys`, replacing signing-key-noisy CLI listing and the separate-worker hybrid with a supervised `/dev/tty` flow and API revalidation.
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
