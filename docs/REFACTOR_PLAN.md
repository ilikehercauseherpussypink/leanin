# Refactor Plan

This branch is a cleanup/refactor branch for the leanin control plane. The goal
is to make the main installer flow explicit and maintainable while preserving
current behavior and safety checks.

## Current Execution Flow

`install.sh` currently owns both bootstrap and runtime orchestration:

1. Set shell safety flags and define `LEANIN_VERSION`, `LEANIN_REPO`,
   `LEANIN_BRANCH`, and `LEANIN_BOOTSTRAPPED`.
2. Parse a small early option subset for `--version`, `--help`, `--plan`, and
   `--verbose`; reject unknown options before any bootstrap work.
3. Print the initial banner unless the script is already running from a
   bootstrapped temporary copy.
4. Run `bootstrap_project`.
   - If `install.sh`, `lib/`, `apps/`, and `services/` are local, set
     `LEANIN_ROOT` and continue.
   - If invoked through a pipe, validate `LEANIN_REPO` and `LEANIN_BRANCH`,
     download a GitHub branch tarball, validate the archive layout, extract it
     under a private temporary directory, and re-exec the extracted
     `install.sh`.
5. Source feature modules from `lib/`.
6. Initialize runtime globals for flags, step state, logs, failures, skip state,
   and plan loading.
7. Parse full CLI options.
8. Enforce CI restrictions.
9. Run read-only `doctor` or `plan` modes and return early.
10. Load package and service lists.
11. Calculate dynamic step count.
12. Run the main phases:
    - `sistema`: validate Arch, non-root user, sudo, network, pacman lock, and
      state/log setup; CI mode uses `/dev/null` logs and skips host mutation
      checks.
    - `plano`: validate and print configured apps, services, and disabled
      features.
    - `pacotes`: pacman core, Flatpak setup/apps, pacman rest, AUR helper and
      AUR apps.
    - `serviços`: system and user services, if configured and not skipped.
    - `Codex`: npm prefix, CLI install, and PATH setup.
    - `Git`: identity and preferences.
    - `SSH`: local key handling.
    - `GitHub`: GitHub SSH key registration and SSH test.
    - `resumo`: logs, counts, failures, and manual next steps.

## Function Ownership

### Bootstrap

- `initial_banner`
- `bootstrap_fail`
- `validate_bootstrap_repo`
- `validate_bootstrap_branch`
- `bootstrap_project`
- early option scan for bootstrap-safe exits

### CLI Parsing

- `usage`
- `parse_args`
- early option scan
- option default globals:
  `VERBOSE`, `DRY_RUN`, `PLAN_ONLY`, `DOCTOR_ONLY`, `ASSUME_YES`,
  `CI_MODE`, and all `SKIP_*` flags

### Planning

- `collect_disabled_features`
- `plan_status`
- `plan_count`
- `print_verbose_plan`
- `show_plan_only`
- `load_plan`
- `packages_enabled`
- `print_disabled_plan`

### Execution

- `calculate_total_steps`
- `install_packages`
- `next_step`
- `main`
- feature calls into `lib/pkg`, `lib/flatpak`, `lib/aur`, `lib/service`,
  `lib/codex`, `lib/git`, `lib/ssh`, and `lib/gh`

### Summary

- `summary_line`
- `log_list`
- `has_failure`
- `count_failures`
- `summary_counts`
- `show_summary`

### Feature Modules

- `lib/apps`: app list parsing, validation, and app plan printing
- `lib/ask`: prompts and safe default handling
- `lib/aur`: AUR helper detection/bootstrap and AUR package installation
- `lib/codex`: Codex npm prefix, CLI install, and PATH setup
- `lib/doctor`: read-only diagnostics
- `lib/env`: host preflight checks, state/log setup, pacman lock state
- `lib/flatpak`: Flatpak/Flathub setup and app installation
- `lib/gh`: GitHub CLI auth state, SSH key API integration, and fallback
- `lib/git`: Git identity and preference configuration
- `lib/log`: logging, redaction, and message helpers
- `lib/pkg`: pacman package installation
- `lib/run`: command execution, sudo, capture, dry-run, and redacted logging
- `lib/service`: service list parsing and activation
- `lib/ssh`: local SSH key handling and GitHub SSH test

## Shared Global Variables

The installer relies on shell globals across modules. These are the important
shared contracts to preserve during refactor:

- Runtime options: `VERBOSE`, `DRY_RUN`, `PLAN_ONLY`, `DOCTOR_ONLY`,
  `ASSUME_YES`, `CI_MODE`, `SKIP_PACMAN`, `SKIP_FLATPAK`, `SKIP_AUR`,
  `SKIP_SERVICES`, `SKIP_CODEX`, `SKIP_GIT`, `SKIP_SSH`, `SKIP_GITHUB`
- Bootstrap identity: `LEANIN_VERSION`, `LEANIN_REPO`, `LEANIN_BRANCH`,
  `LEANIN_BOOTSTRAPPED`, `LEANIN_ROOT`
- Control state: `TOTAL_STEPS`, `STEP_CURRENT`, `PACMAN_BLOCKED`,
  `LOG_FILE`, `FAILURES`, `DISABLED_FEATURES`, `PLAN_LOADED`
- App plan state: `PACMAN_APPS`, `PACMAN_CORE`, `PACMAN_REST`,
  `FLATPAK_APPS`, `AUR_APPS`, `APP_COUNTS`, `APP_ITEMS`, `APP_SEEN`
- Package results: `PACMAN_INSTALLED`, `PACMAN_SKIPPED`, `PACMAN_PLANNED`,
  `PACMAN_ALREADY`, `FLATPAK_INSTALLED`, `FLATPAK_SKIPPED`,
  `FLATPAK_PLANNED`, `FLATPAK_ALREADY`, `AUR_INSTALLED`, `AUR_SKIPPED`,
  `AUR_PLANNED`, `AUR_ALREADY`, `AUR_HELPER`
- Service state: `SYSTEM_SERVICES`, `USER_SERVICES`, `SERVICES_ACTIVATED`,
  `SERVICES_ALREADY`, `SERVICES_SKIPPED`, `SERVICES_PLANNED`
- Codex state: `CODEX_PREFIX`, `CODEX_PATH_LINE`, `CODEX_FISH_LINE`,
  `CODEX_PATH_ALREADY`, `CODEX_PATH_SKIPPED`, `CODEX_PATH_CHANGED`,
  `CODEX_PREFIX_READY`
- SSH/GitHub state: `SSH_PRIVATE_KEY`, `SSH_PUBLIC_KEY`, `SSH_CLIPBOARD`,
  `SSH_GITHUB_RESULT`, `SSH_KEY_WAS_EXISTING`, `SSH_KEY_CREATED`,
  `SSH_BACKUP_PRIVATE`, `SSH_BACKUP_PUBLIC`, `GITHUB_KEYS_URL`,
  `GITHUB_KEY_TITLE`, `GITHUB_NEW_KEY_STATUS`, `GITHUB_OLD_KEYS_STATUS`,
  `GITHUB_SSH_MANAGEMENT_STATUS`, `GH_STATE`, `GITHUB_KEY_IDS`,
  `GITHUB_KEY_TITLES`, `GITHUB_KEY_VALUES`, `GITHUB_OLD_KEY_IDS`,
  `GITHUB_OLD_KEY_TITLES`, `GITHUB_OLD_KEY_VALUES`
- Git identity summary state: `GIT_NAME`, `GIT_EMAIL`

## Duplicated Logic

`scripts/check` duplicates or partially reimplements production behavior in
several places:

- Logging helpers duplicate `ok`, `skip`, `error`, and `step`.
- App list parsing via `app_lines` duplicates trim/comment handling from
  `lib/apps`.
- Service list validation duplicates parsing and format checks from
  `lib/service`.
- Option flag lists are separately encoded in installer help, parser, early
  parser, and check expectations.
- Bootstrap safety expectations are hard-coded as source tokens in
  `scripts/check`, tied directly to `install.sh` layout.
- Worker, docs, installer controls, prompt safety, SSH, GitHub, service, and
  Flatpak checks all live in one large script, making it hard to see which
  safety surface failed.

The check suite should remain the public `bash scripts/check` command, but the
categories should move under `scripts/checks/` so structure, Bash syntax,
lists, safety, bootstrap, installer controls, docs, GitHub Actions, and
Cloudflare Worker checks are easier to maintain.

## Repository Identity Inconsistencies

The current repository target should be `uswl/leanin`, but several files still
point to the previous owner:

- `install.sh`: default `LEANIN_REPO`
- `README.md`: CI badge link and clone URL
- `cloudflare/worker.js`: default `OWNER`
- `cloudflare/README.md`: upstream repository URL
- `scripts/check`: bootstrap, docs, and Worker expectations

The remaining `ARCHBOOT_CI` references are intentional compatibility aliases.
Checks already reject other `ARCHBOOT_*` variables and old project branding.

## Refactor Phases

1. Control plane: keep `install.sh` as the entrypoint, keep bootstrap there, and
   move runtime orchestration into `lib/control` or `lib/main`.
2. CLI/options: move option defaults, help, parsing, and early option metadata
   into a dedicated module so help and parser definitions share one source.
3. Plan/pipeline: make phases explicit as `system`, `plan`, `packages`,
   `services`, `codex`, `git`, `ssh`, `github`, and `summary`; centralize skip
   predicates and keep step counting dynamic.
4. Checks: split `scripts/check` into smaller scripts under `scripts/checks/`
   while preserving `bash scripts/check` as the public entrypoint and preserving
   all safety coverage.
5. Docs: document module boundaries in `docs/ARCHITECTURE.md`, update README
   only where it describes structure, and fix stale owner references.

## Guardrails

- Preserve all public flags.
- Preserve pipe install behavior.
- Keep `--doctor`, `--plan`, and `--dry-run` read-only.
- Keep GitHub SSH handling interactive and safe.
- Keep logs redacted.
- Keep pacman lock behavior safe and never remove the lock automatically.
- Keep package, app, and service defaults unchanged except obvious repo/name
  inconsistencies.
- Cover meaningful movement with `scripts/check` or split check scripts.
