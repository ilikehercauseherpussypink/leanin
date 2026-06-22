# Troubleshooting

Start with a read-only check:

```bash
curl -fsSL https://shelies.org | bash -s -- --doctor
bash install.sh --doctor
```

Use dry-run or verbose plan output before changing anything:

```bash
bash install.sh --dry-run
bash install.sh --plan --verbose
```

When an existing setting could be replaced, leanin asks with `[s/N]`. Enter keeps the current state. Prompts use `/dev/tty`, including when the installer starts through `curl | bash`. Without a terminal, the safe default is to keep the current state.

## Pacman lock

leanin never removes `/var/lib/pacman/db.lck`. Close pacman, paru, yay, or another package manager first, then confirm what is running:

```bash
ps -ef | grep -E '[p]acman|[p]aru|[y]ay'
```

Removing a lock without checking the owning process can corrupt a transaction. While the lock exists, pacman and AUR work are skipped.

## Internet

```bash
curl -I https://archlinux.org
curl -fsSL https://shelies.org/health
```

DNS, proxy, system clock, or certificate problems can block downloads.

## Sudo

```bash
command -v sudo
sudo -v
```

Run the installer as a normal user, not root.

## Flatpak and Flathub

```bash
flatpak --version
flatpak remotes
flatpak remote-ls flathub | head
```

Full command output is saved in the run log when setup or installation fails.

## Sober / Roblox

```bash
flatpak run org.vinegarhq.Sober
flatpak info org.vinegarhq.Sober
flatpak update org.vinegarhq.Sober
flatpak remotes
```

Run Sober from a terminal when it does not open to see its output. Roblox or Sober can break after upstream updates.

## AUR helper

```bash
command -v paru || command -v yay
```

leanin prefers paru and accepts yay. If the paru bootstrap fails, verify `git` and `base-devel`, then read the log. It never runs `makepkg` as root.

## Mullvad conflict

`mullvad-vpn-bin` is skipped when `mullvad-vpn-daemon` is already installed. No package is removed automatically.

```bash
pacman -Q mullvad-vpn-daemon mullvad-vpn-bin
systemctl status mullvad-daemon.service
```

## GitHub CLI authenticated but SSH key management unavailable

```bash
gh auth status
```

`gh auth status` can be OK while the authentication-key API still fails.

For a fresh login, use:

```bash
gh auth login -h github.com -p ssh -s admin:public_key --web
```

For an existing weak login, use:

```bash
gh auth refresh -h github.com -s admin:public_key
```

Verify and rerun leanin:

```bash
gh api user/keys
curl -fsSL https://shelies.org | bash
ssh -T git@github.com
```

`admin:public_key` is required because leanin lists, adds, and optionally removes Git SSH authentication keys through `gh api user/keys`. During a normal interactive run, leanin uses a **supervised same-terminal flow** through `/dev/tty`; `curl | bash` never feeds its input to `gh`. When `gh` returns, leanin revalidates both `gh auth status` and `gh api user/keys` before it registers a key. The authentication-key backend does not query the SSH signing-key API, so signing-key scope warnings do not affect this setup.

Local keys stay in `~/.ssh`. If automatic registration cannot continue, manual registration at <https://github.com/settings/keys> remains safe: add the public `.pub` key shown by the installer, then run the SSH test above. Local SSH files are never deleted.

## GitHub authentication looks stuck

During GitHub CLI device authentication, you may see a one-time code and a prompt to press Enter before opening `https://github.com/login/device`. Copy the code, authenticate in the browser, return to the same terminal and press Enter if GitHub CLI is still waiting. leanin then rechecks API access before it registers the local key.

For existing weak scopes:

```bash
gh auth refresh -h github.com -s admin:public_key
gh api user/keys
curl -fsSL https://shelies.org | bash
```

## Codex PATH

```bash
command -v codex
codex --version
printf '%s\n' "$PATH" | tr ':' '\n' | grep -F "$HOME/.codex/bin"
```

Open a new terminal after the PATH changes. An older Codex installation in another prefix is not removed automatically.

## Cloudflare and the short domain

```bash
curl -fsSL https://shelies.org/health
curl -fsSL https://shelies.org | head
curl -fsSL https://archboot.jocaluvero.workers.dev/health
```

The Worker serves `install.sh` from GitHub. A `502` usually means that the upstream could not be fetched.

## Logs

Every real run creates a log under `~/.local/state/leanin/logs`. Existing archboot logs are left untouched.

```bash
ls -1t ~/.local/state/leanin/logs | head
tail -n 120 ~/.local/state/leanin/logs/FILE.log
```

Use `--verbose` only when you need full command output in the terminal. Review a log before sharing it.
