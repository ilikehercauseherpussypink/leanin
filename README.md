# archboot

Bootstrap modular, auditável e idempotente para preparar uma instalação Arch Linux com apps base, ambiente de desenvolvimento, Flatpak/Flathub, AUR, Codex CLI, Git, SSH e GitHub CLI.

O instalador usa Bash estrito, bloqueia execução como root, usa `sudo` somente onde necessário e salva a saída técnica em `~/.local/state/archboot/logs`.

## Execução

Auditar antes de executar é a opção recomendada:

```bash
curl -fsSL https://raw.githubusercontent.com/ilikehercauseherpussypink/archboot/main/install.sh -o install.sh
less install.sh
bash install.sh
```

Execução direta:

```bash
curl -fsSL https://raw.githubusercontent.com/ilikehercauseherpussypink/archboot/main/install.sh | bash
```

`curl | bash` é conveniente, mas revisar o script antes é mais seguro.

Para usar outro fork ou branch:

```bash
ARCHBOOT_REPO="https://github.com/ilikehercauseherpussypink/archboot" ARCHBOOT_BRANCH="main" bash install.sh
```

Execução local e modos auxiliares:

```bash
bash install.sh
bash install.sh --verbose
bash install.sh --dry-run
bash install.sh --dry-run --verbose
```

## Como o bootstrap funciona

Quando `install.sh` encontra `lib/`, `apps/` e `services/` ao lado dele, usa o checkout local. Quando chega sozinho por pipe, baixa o tarball da branch configurada para um diretório criado com `mktemp -d`, extrai o projeto, reexecuta o instalador com `ARCHBOOT_BOOTSTRAPPED=1` e remove o diretório temporário ao terminar. O fluxo não depende de `git clone`; apenas `curl` e `tar` são exigidos para o bootstrap remoto.

## Cloudflare Worker

Um domínio curto pode apontar para o Worker em `cloudflare/`. Ele funciona apenas como proxy seguro do `install.sh` armazenado no GitHub; a fonte real continua sendo o repositório, e o script mantém o fluxo self-bootstrapping que baixa o tarball completo quando necessário.

Execução pelo domínio curto:

```bash
curl -fsSL https://archboot.jocaluvero.workers.dev | bash
```

Auditoria antes da execução:

```bash
curl -fsSL https://archboot.jocaluvero.workers.dev -o install.sh
less install.sh
bash install.sh
```

Consulte [`cloudflare/README.md`](cloudflare/README.md) para configurar o Wrangler, associar o domínio e publicar o Worker.

## O que é instalado

Os defaults incluem ferramentas base e dev dos repositórios Arch, EasyEffects, Tor Browser Launcher, Discord, Spotify, Tuta Mail, Bitwarden, Mullvad Browser, LibreWolf, Mullvad VPN e Wootility. Flatpak e Flathub são configurados de forma idempotente. O Codex CLI usa exclusivamente `npm install -g @openai/codex` com prefixo em `~/.codex`.

Git, SSH e autenticação GitHub ficam no final para não bloquear a instalação dos apps. Falhas de pacotes individuais são registradas e as etapas independentes continuam.

## Personalizar apps

Edite os arquivos dentro de `apps/`; o `install.sh` não mantém uma lista hardcoded de aplicativos.

* `apps/pacman/`: integração nativa com Arch, indicada para CLI, sistema, serviços e pacotes oficiais.
* `apps/pacman/audio`: categoria de áudio; inclui `easyeffects` dos repositórios oficiais do Arch.
* `apps/flatpak/`: apps desktop isolados, atualizados pelo Flathub e com menor acoplamento ao sistema.
* `apps/aur/`: pacotes comunitários do Arch; revise PKGBUILDs e use com mais cuidado.

Cada linha contém um pacote ou ID. Linhas vazias e comentários iniciados por `#` são ignorados. Comentários inline são aceitos depois de espaço e `#`.

Para adicionar ou remover um app, altere apenas o arquivo da categoria. Para mover um app de Flatpak para AUR, remova o ID de `apps/flatpak/*` e adicione o nome AUR em `apps/aur/*`. Para mover de AUR para pacman, remova o nome de `apps/aur/*` e adicione o nome oficial em `apps/pacman/*`. Confirme sempre o nome na fonte escolhida; o instalador não adivinha alternativas.

Alguns defaults podem ser trocados dessa forma. `net.mullvad.MullvadBrowser` é uma opção prática no Flathub, mas atualmente é um pacote comunitário e não verificado; usuários exigentes podem preferir AUR ou instalação manual. O Flatpak de Tuta também é apresentado pelo Flathub como experimental/comunitário.

## Serviços

Os serviços também são modulares. Edite `services/system` para units de sistema e `services/user` para units da sessão do usuário. Linhas vazias e comentários iniciados por `#` são ignorados.

Serviços de sistema são ativados com `sudo systemctl enable --now SERVICE`. Serviços do usuário usam `systemctl --user enable --now SERVICE`. O instalador verifica se a unit existe, preserva serviços já ativos e registra falhas sem interromper as demais etapas.

O default inclui `mullvad-daemon.service` em `services/system`. Quando a unit estiver disponível, o archboot a ativa; se não existir, apenas registra o skip.

## AUR e segurança

O archboot prefere `paru`, usa `yay` quando disponível e pergunta antes de instalar o paru. `makepkg` e helpers AUR nunca rodam como root. Se `/var/lib/pacman/db.lck` existir, pacman e AUR são pulados; o lock nunca é removido automaticamente.

## Git, SSH e GitHub

O instalador mostra a identidade Git global, pede confirmação antes de alterá-la e nunca sobrescreve uma chave privada SSH. A chave pública pode ser copiada com `wl-copy` ou `xclip`.

Quando `gh` está autenticado, o archboot usa `gh api user/keys` para obter a lista estruturada de chaves SSH da conta, oferece opcionalmente remover todas com uma confirmação `s/N` cujo padrão é não, e cadastra a chave atual com `gh ssh-key add`. O título padrão é `person` e pode ser alterado no prompt. Essa limpeza afeta somente as chaves remotas do GitHub; nenhum arquivo em `~/.ssh` é removido.

Se o cadastro automático não estiver disponível, a página abaixo permanece como fallback manual:

https://github.com/settings/keys

Teste a conexão depois de salvar a chave:

```bash
ssh -T git@github.com
```

O login da GitHub CLI é opcional e usa `gh auth login --web`; nenhum token é solicitado ou salvo manualmente pelo script.

## Codex CLI

O PATH `~/.codex/bin` é adicionado sem duplicação a `~/.profile` e aos arquivos existentes de Bash/Zsh. Fish recebe `fish_add_path "$HOME/.codex/bin"` quando Fish ou sua configuração existe.

Teste:

```bash
command -v codex
codex --version
```

Para desfazer parcialmente:

```bash
npm config delete prefix
```

Depois, remova a linha de `~/.codex/bin` dos arquivos de shell e remova `~/.codex` se não precisar mais do conteúdo.

## Atualizações e remoção

```bash
sudo pacman -Syu
flatpak update
paru -Syu
# ou: yay -Syu

flatpak list --app
flatpak uninstall APP_ID
```

Mullvad VPN é apenas instalada; login e conexão permanecem manuais:

O default `mullvad-vpn-bin` inclui `mullvad-vpn-daemon-bin`. Se o sistema já tiver `mullvad-vpn-daemon`, o archboot pula `mullvad-vpn-bin` para evitar conflito. O script preserva a instalação existente e nunca remove ou substitui automaticamente pacotes Mullvad; escolha conscientemente uma das variantes antes de fazer qualquer troca manual.

```bash
mullvad status
mullvad account login
mullvad connect
mullvad disconnect
```

## Wootility no Linux

Wootility fica inicialmente em `apps/aur/tools`. No Linux, o acesso ao teclado pode exigir regras udev. Consulte a [documentação oficial da Wooting](https://help.wooting.io/article/147-configuring-device-access-for-wootility-under-linux-udev-rules). O archboot não cria regras automaticamente.

## Validar e publicar

```bash
bash scripts/check
bash scripts/github
```

`scripts/check` valida sintaxe, estrutura, listas, formatos prováveis, segredos óbvios e executa ShellCheck quando disponível. `scripts/github` mostra o status curto, pede confirmação antes de commit/push e cria o commit inicial `feat: add arch bootstrap installer`.

## Testes rápidos

```bash
bash scripts/check
bash install.sh --dry-run
command -v codex
codex --version
ssh -T git@github.com
mullvad status
```

## Licença

MIT.
