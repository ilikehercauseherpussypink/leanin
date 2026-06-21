<div align="center">

# 〖 archboot 〗

personal Arch Linux bootstrap<br>
apps / dev tools / ssh / github / codex / services

[![check](https://github.com/ilikehercauseherpussypink/archboot/actions/workflows/check.yml/badge.svg)](https://github.com/ilikehercauseherpussypink/archboot/actions/workflows/check.yml)
[![license](https://img.shields.io/badge/license-MIT-111111.svg)](LICENSE)
[![shell](https://img.shields.io/badge/shell-bash-111111.svg)](install.sh)

<br>
<code>curl -fsSL https://shelies.org | bash</code>

</div>

## // what is this

`archboot` is my personal Arch Linux bootstrap. It installs my usual stack, wires up Flatpak/AUR, Codex, Git, SSH, GitHub and services, then stays out of the way. It follows main; it is not a distro installer or a universal framework.

## // install

```bash
curl -fsSL https://shelies.org | bash
```

```bash
# check the machine without changing it
curl -fsSL https://shelies.org | bash -s -- --doctor

# preview actions
curl -fsSL https://shelies.org | bash -s -- --dry-run

# inspect the package and service plan
curl -fsSL https://shelies.org | bash -s -- --plan
```

Run `--doctor` first when the machine is new or questionable.

## // audit first

```bash
curl -fsSL https://shelies.org -o install.sh
less install.sh
bash install.sh --dry-run
bash install.sh
```

Piping is convenient. Downloading and reading the script first is safer.

## // what it does

| Area | What happens |
| --- | --- |
| pacman | Base, development and system packages |
| Flatpak | Flathub setup and desktop apps |
| AUR | paru/yay packages |
| services | System and user units |
| Codex | npm prefix at `~/.codex` |
| Git / SSH | Identity, local key and GitHub registration |

## // default stack

```text
pacman   curl ca-certificates base-devel flatpak git openssh nodejs npm github-cli torbrowser-launcher easyeffects
flatpak  Discord Spotify Tuta Bitwarden Mullvad Browser Sober (org.vinegarhq.Sober)
aur      LibreWolf Mullvad VPN Wootility
service  mullvad-daemon.service
```

Full package IDs, category files and customization notes live in [docs/APPS.md](docs/APPS.md).

## // layout

```text
apps/
  pacman/
  flatpak/
  aur/
services/
  system
  user
lib/
scripts/
cloudflare/
```

Apps and services are editable files. Empty lines and `# comments` are ignored.

## // controls

| Flag | Meaning |
| --- | --- |
| `--doctor` | Check the environment only |
| `--dry-run` | Show actions without changing the system |
| `--plan` | Show the package and service plan |
| `--yes` | Safe defaults; no destructive confirmations |
| `--no-flatpak` | Skip Flatpak and Flathub |
| `--no-aur` | Skip AUR |
| `--no-ssh` | Skip SSH and GitHub key flow |

<details>
<summary>More controls</summary>

`--version`, `--verbose`, `--no-packages`, `--no-pacman`, `--no-services`, `--no-codex`, `--no-git` and `--no-github` are also available. Run `bash install.sh --help` for the complete list.

</details>

## // safety model

* No package removals.
* No local SSH key deletion.
* Prompts before replacing existing state; Enter keeps it.
* `--doctor`, `--plan` and `--dry-run` are read-only.
* Logs are restricted and redact common token/key patterns.
* The pacman lock is never removed automatically.
* `--yes` keeps safe defaults instead of forcing replacements.

Details: [docs/SAFETY.md](docs/SAFETY.md).

## // commands I actually use

```bash
curl -fsSL https://shelies.org | bash -s -- --doctor
curl -fsSL https://shelies.org | bash -s -- --dry-run
curl -fsSL https://shelies.org | bash
flatpak run org.vinegarhq.Sober
```

## // docs

* [Troubleshooting](docs/TROUBLESHOOTING.md)
* [Apps and customization](docs/APPS.md)
* [Safety notes](docs/SAFETY.md)
* [Changelog](CHANGELOG.md)
* [Cloudflare Worker](cloudflare/README.md)

## // local dev

```bash
git clone https://github.com/ilikehercauseherpussypink/archboot
cd archboot
bash scripts/check
bash install.sh --dry-run
```

## // license

MIT.
