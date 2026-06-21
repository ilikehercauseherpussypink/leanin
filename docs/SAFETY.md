# Safety notes

`archboot` is designed for a personal machine, but it keeps the risky parts explicit.

## Modes

| Mode | Behavior |
| --- | --- |
| `--doctor` | Read-only environment checks |
| `--plan` | Read-only package and service overview |
| `--dry-run` | Shows mutable actions without running them |
| `--yes` | Uses safe defaults; it does not force replacements |

`ARCHBOOT_CI=1` only permits safe modes.

## Existing state

Enter keeps the existing Git identity, SSH key, Codex installation, divergent npm prefix, GitHub key state and inactive service state unless a safe action is explicitly accepted. Local SSH keys are never deleted; a confirmed regeneration creates backups and restores them if generation fails.

When started through `curl | bash`, prompts and `ssh-keygen` use `/dev/tty` when available. Without a terminal, the installer keeps the safe default and refuses interactive key generation.

## Packages and services

The installer never removes packages, clears the pacman lock or enables a missing service. It verifies the pacman lock before package work and treats the Mullvad package conflict as a skip.

## Remote bootstrap and logs

The short domain serves `install.sh`; the script then downloads the repository tarball from GitHub into a temporary directory and validates its layout before continuing. The repository/branch override inputs are restricted to safe GitHub HTTPS values.

Real runs log to `~/.local/state/archboot/logs` with restrictive permissions. Common token patterns and private-key blocks are redacted, but inspect logs before sharing them.
