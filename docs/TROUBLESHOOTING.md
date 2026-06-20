# Troubleshooting

Comece pelo doctor para obter um diagnóstico rápido sem alterar o sistema:

```bash
curl -fsSL https://shelies.org | bash -s -- --doctor
bash install.sh --doctor
```

Use o plano ou o dry-run para inspecionar as ações seguintes:

```bash
bash install.sh --dry-run
bash install.sh --plan --verbose
```

Ao encontrar uma configuração existente que poderia ser substituída, o archboot pergunta com `[s/N]`. Enter mantém o estado atual. Os prompts leem o terminal real (`/dev/tty`), inclusive quando o instalador foi iniciado com `curl | bash`. Sem terminal disponível, o default seguro é manter o estado. `--yes` também preserva esse default seguro: ele instala somente o que falta e não força reconfigurações. No fluxo GitHub, o título da chave só é solicitado após a confirmação de cadastro de uma chave ainda ausente.

## Pacman lock

O archboot não remove `/var/lib/pacman/db.lck`. Feche pacman, paru, yay ou outro gerenciador em execução e confirme o processo antes de agir:

```bash
ps -ef | grep -E '[p]acman|[p]aru|[y]ay'
```

Remover o lock sem verificar o processo pode corromper uma transação. Enquanto ele existir, pacotes pacman e AUR são pulados.

## Internet

Teste acesso HTTPS ao Arch Linux e a saúde do domínio do instalador:

```bash
curl -I https://archlinux.org
curl -fsSL https://shelies.org/health
```

Falhas de DNS, proxy, relógio do sistema ou certificados podem impedir downloads.

## Sudo

O instalador deve rodar como usuário comum com `sudo` disponível:

```bash
command -v sudo
sudo -v
```

Não execute o script inteiro como root.

## Flatpak e Flathub

Confira a ferramenta, os remotes e o acesso ao Flathub:

```bash
flatpak --version
flatpak remotes
flatpak remote-ls flathub | head
```

O output completo da configuração ou instalação com falha fica no log da execução.

## AUR helper

O archboot prefere paru e aceita yay. Verifique o helper disponível:

```bash
command -v paru || command -v yay
```

Se o bootstrap do paru falhar, confirme que `git` e `base-devel` estão instalados e consulte o log. O script nunca executa `makepkg` como root.

## Mullvad conflict

Se `mullvad-vpn-daemon` já estiver instalado, `mullvad-vpn-bin` é pulado para evitar substituição ou conflito. Nenhum pacote é removido automaticamente.

Confira pacote e serviço:

```bash
pacman -Q mullvad-vpn-daemon mullvad-vpn-bin
systemctl status mullvad-daemon.service
```

## GitHub CLI auth

Confira a sessão atual e autentique novamente quando necessário:

```bash
gh auth status
gh auth login
```

O archboot não solicita nem armazena token manualmente.

## SSH key e GitHub

Teste a autenticação diretamente:

```bash
ssh -T git@github.com
```

As chaves locais ficam em `~/.ssh`. Se o cadastro automático via `gh` não funcionar, use o caminho `.pub` mostrado pelo instalador para o cadastro manual. O script não deleta arquivos SSH locais.

## Codex PATH

O binário esperado fica em `~/.codex/bin/codex`:

```bash
command -v codex
codex --version
printf '%s\n' "$PATH" | tr ':' '\n' | grep -F "$HOME/.codex/bin"
```

Abra um terminal novo se o PATH acabou de ser alterado. Uma instalação antiga em outro prefixo não é removida automaticamente.

## Cloudflare e domínio

Teste o health check, o script servido e o Worker direto:

```bash
curl -fsSL https://shelies.org/health
curl -fsSL https://shelies.org | head
curl -fsSL https://archboot.jocaluvero.workers.dev/health
```

O Worker apenas entrega o `install.sh` do GitHub. Um `502` normalmente indica que o upstream não pôde ser obtido.

## Logs

Cada instalação real cria um log em `~/.local/state/archboot/logs`. Use o caminho exibido no resumo:

```bash
ls -1t ~/.local/state/archboot/logs | head
tail -n 120 ~/.local/state/archboot/logs/ARQUIVO.log
```

Repita com `--verbose` somente quando precisar acompanhar a saída completa no terminal. Não publique logs sem revisar seu conteúdo.
