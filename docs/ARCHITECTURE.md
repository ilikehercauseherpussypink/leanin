# Architecture

`install.sh` stays as the public entrypoint. Its job is intentionally small:
handle early `--help` and `--version`, keep pipe-install bootstrap safe, source
the local modules, and call the installer control plane.

## Runtime Modules

* `lib/options`: option defaults, help text, strict argument parsing, and
  disabled-feature collection.
* `lib/control`: phase order, phase enablement, step counting, orchestration,
  plan output, package grouping, and final summary.
* `lib/env`: host preflight checks, state directory setup, logging paths, and
  pacman lock detection.
* `lib/apps`: package-list loading, validation, counts, and plan details.
* `lib/pkg`, `lib/flatpak`, `lib/aur`: package-source-specific installation
  behavior.
* `lib/service`: service-list loading and system/user service activation.
* `lib/codex`, `lib/git`, `lib/ssh`, `lib/gh`: feature modules for local tool
  configuration and GitHub SSH integration.
* `lib/ask`, `lib/run`, `lib/log`: shared prompting, command execution, dry-run,
  and redacted logging helpers.
* `lib/doctor`: read-only environment diagnostics.

## Installer Phases

The control plane runs these phases in order:

1. `system`
2. `plan`
3. `packages`
4. `services`
5. `codex`
6. `git`
7. `ssh`
8. `github`
9. `summary`

`lib/control` owns phase enablement and dynamic step counting. Feature modules
own the commands for their domain, but they read the shared option, log, and
result globals set by the control plane and supporting modules.

## Checks

`bash scripts/check` is the public check command. It sources focused checks from
`scripts/checks/` for common helpers, structure, Bash syntax, and app/service
lists, then continues through the safety, bootstrap, installer-control,
documentation, workflow, Worker, secret, and ShellCheck validations.

The check suite intentionally uses source-token assertions for safety-sensitive
behavior such as bootstrap validation, redaction, pacman lock handling, and
GitHub SSH registration. When code moves, the assertions should move with it
rather than being removed.
