# Apps and customization

`apps/` is the only place to change the default software list. The installer reads every category file under each source.

```text
apps/
  pacman/   base dev browsers audio privacy system
  flatpak/  chat media mail privacy games tools
  aur/      browsers privacy media tools
```

| Source | Use it for |
| --- | --- |
| `pacman` | Native Arch packages and CLI tools |
| `flatpak` | Desktop apps from Flathub |
| `aur` | Community packages that do not fit the other sources |
| npm | Codex only; it is not listed in `apps/` |

## Current defaults

| Source | Entries |
| --- | --- |
| pacman | `curl`, `ca-certificates`, `base-devel`, `flatpak`, `git`, `openssh`, `nodejs`, `npm`, `github-cli`, `torbrowser-launcher`, `easyeffects` |
| Flatpak | `com.discordapp.Discord`, `com.spotify.Client`, `com.tutanota.Tutanota`, `com.bitwarden.desktop`, `net.mullvad.MullvadBrowser`, `org.vinegarhq.Sober` |
| AUR | `librewolf-bin`, `mullvad-vpn-bin`, `wootility` |

## Edit the lists

```bash
echo fastfetch >> apps/pacman/system
echo org.example.App >> apps/flatpak/tools
echo package-name >> apps/aur/tools
echo example.service >> services/system
```

Empty lines and comments are ignored. `bash scripts/check` catches obvious format mistakes and duplicate entries in the same source.

Move an app by removing it from one source file and adding the correct identifier to another. The installer does not try to guess alternatives.

## Notes

* Sober is a Flathub app: `flatpak run org.vinegarhq.Sober`.
* Mullvad Browser on Flathub may be community maintained. Move it if you prefer another source.
* `mullvad-vpn-bin` is skipped when `mullvad-vpn-daemon` is already installed to avoid a conflict.
* Wootility may need udev rules on Linux. The installer does not invent them.
