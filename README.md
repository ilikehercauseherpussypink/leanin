# archboot

Bootstrap modular para Arch Linux, feito para instalar apps, configurar dev tools, Codex, Git, SSH, GitHub, Flatpak, AUR e serviços com output limpo.

## Quick start

```bash
curl -fsSL https://shelies.org | bash
```

Dry-run, sem alterar o sistema:

```bash
curl -fsSL https://shelies.org | bash -s -- --dry-run
```

Mostrar somente o plano:

```bash
curl -fsSL https://shelies.org | bash -s -- --plan
```

Mostrar a versão:

```bash
curl -fsSL https://shelies.org | bash -s -- --version
```

Modo verbose:

```bash
curl -fsSL https://shelies.org | bash -s -- --verbose
```

## Safer audit-first install

```bash
curl -fsSL https://shelies.org -o install.sh
less install.sh
bash install.sh
```

Executar via `curl | bash` é conveniente, mas baixar e auditar o script antes é a opção mais segura.

## Doctor

```bash
curl -fsSL https://shelies.org | bash -s -- --doctor
bash install.sh --doctor
```

O doctor verifica rapidamente o ambiente e as integrações principais sem instalar, configurar ou remover nada. É útil antes da instalação real.

## Installer controls

Exemplos locais:

```bash
bash install.sh --dry-run --no-ssh --no-github
bash install.sh --yes
bash install.sh --plan --verbose
```

Flags disponíveis:

* `--plan`: mostra apps, serviços e integrações habilitadas sem executar ações.
* `--doctor`: diagnostica sistema, ferramentas e integrações sem alterar o ambiente.
* `--version`: imprime a versão do archboot.
* `--yes`: usa defaults seguros sem prompts; não sobrescreve identidade ou chave existente e nunca confirma exclusões perigosas.
* `--no-packages`: desativa pacman, Flatpak e AUR.
* `--no-pacman`: desativa pacotes dos repositórios Arch.
* `--no-flatpak`: desativa Flatpak, Flathub e apps Flatpak.
* `--no-aur`: desativa helper e pacotes AUR.
* `--no-services`: não ativa serviços system/user.
* `--no-codex`: não configura ou instala Codex.
* `--no-git`: não altera configuração Git.
* `--no-ssh`: não configura SSH e também desativa a integração GitHub SSH.
* `--no-github`: não cadastra chave, testa SSH GitHub ou executa autenticação `gh`.

`--yes` significa "non-interactive safe defaults", não confirmação irrestrita. Quando não existe um default seguro, a ação é pulada com aviso.

## What it does

* Instala pacotes pacman.
* Configura Flatpak e Flathub.
* Instala Flatpaks.
* Instala pacotes AUR via paru ou yay.
* Configura serviços system e user.
* Configura o Codex CLI em `~/.codex`.
* Configura a identidade Git global.
* Cria ou reutiliza uma chave SSH.
* Cadastra a chave SSH no GitHub via `gh`.
* Usa fallback manual quando `gh` não está disponível.
* Mantém logs em `~/.local/state/archboot/logs`.

O instalador executa 13 etapas. Quando recebido sozinho pelo domínio curto, o `install.sh` baixa o projeto completo pelo tarball da branch configurada e continua a execução a partir de um diretório temporário seguro.

Overrides remotos aceitam somente repositórios GitHub HTTPS no formato `https://github.com/OWNER/REPO` e nomes de branch sem espaços, traversal ou metacaracteres de shell.

## Apps

As listas são editáveis e ficam separadas por fonte e categoria:

```text
apps/
├── pacman/
│   ├── base
│   ├── dev
│   ├── browsers
│   ├── audio
│   ├── privacy
│   └── system
├── flatpak/
│   ├── chat
│   ├── media
│   ├── mail
│   ├── privacy
│   └── tools
└── aur/
    ├── browsers
    ├── privacy
    ├── media
    └── tools
```

* `pacman`: integração nativa com Arch Linux.
* `flatpak`: apps desktop distribuídos pelo Flathub.
* `aur`: pacotes comunitários do Arch, instalados com mais cautela.
* `npm`: usado somente para o Codex CLI e não aparece em `apps/`.

EasyEffects fica em `apps/pacman/audio`; novas categorias podem ser adicionadas como arquivos no diretório da fonte correspondente.

Defaults pacman:

* `curl`
* `ca-certificates`
* `base-devel`
* `flatpak`
* `git`
* `openssh`
* `nodejs`
* `npm`
* `github-cli`
* `torbrowser-launcher`
* `easyeffects`

Defaults Flatpak:

* `com.discordapp.Discord`
* `com.spotify.Client`
* `com.tutanota.Tutanota`
* `com.bitwarden.desktop`
* `net.mullvad.MullvadBrowser`

Defaults AUR:

* `librewolf-bin`
* `mullvad-vpn-bin`
* `wootility`

O Mullvad Browser no Flathub pode ser mantido pela comunidade. Wootility no Linux pode exigir regras udev; o archboot não cria regras automaticamente.

## Services

Os serviços também são configuráveis por arquivo:

* `services/system`: executa `sudo systemctl enable --now SERVICE`.
* `services/user`: executa `systemctl --user enable --now SERVICE`.

O default é `mullvad-daemon.service` em `services/system`. Se a unit não existir, o script pula. Se já estiver ativa, registra como skip/ativa. O dry-run nunca ativa serviços.

## Git, SSH and GitHub

O archboot configura a identidade Git global e mantém as chaves SSH dentro de `~/.ssh`. Um nome relativo como `personal` vira `~/.ssh/personal`; caminhos fora de `~/.ssh` são rejeitados.

O título padrão da chave no GitHub é `person`, mas pode ser alterado no prompt. Quando `gh` está autenticado, a chave é cadastrada automaticamente. Sem `gh`, ou se o cadastro falhar, o fallback manual copia ou mostra a chave pública.

O script pode remover as SSH keys antigas cadastradas no GitHub somente após confirmação. O default é não. Essa operação nunca remove arquivos locais de `~/.ssh`.

## Codex

O Codex usa prefixo npm dedicado:

```text
~/.codex
```

Instalação executada:

```bash
npm install -g @openai/codex
```

O diretório `~/.codex/bin` recebe prioridade no `PATH` de forma idempotente. Instalações antigas do Codex encontradas em outro prefixo geram aviso e não são removidas automaticamente.

## Mullvad

`mullvad-vpn-bin` pode conflitar com `mullvad-vpn-daemon`. Se `mullvad-vpn-daemon` já estiver instalado, o archboot pula `mullvad-vpn-bin` para preservar o sistema. Nenhum pacote é removido automaticamente.

O serviço padrão é `mullvad-daemon.service`.

```bash
mullvad status
mullvad account login
mullvad connect
mullvad disconnect
```

## Cloudflare short domain

`https://shelies.org` aponta para um Cloudflare Worker que serve exatamente o `install.sh` do GitHub. O script recebido faz self-bootstrap e baixa o projeto completo por tarball.

Health check:

```bash
curl -fsSL https://shelies.org/health
```

URL direta do Worker: `https://archboot.jocaluvero.workers.dev`

## Local usage

```bash
git clone https://github.com/ilikehercauseherpussypink/archboot
cd archboot
bash scripts/check
bash install.sh --dry-run
bash install.sh
```

## Customize

Adicionar um pacote pacman:

```bash
echo fastfetch >> apps/pacman/system
```

Adicionar um Flatpak:

```bash
echo org.example.App >> apps/flatpak/tools
```

Adicionar um pacote AUR:

```bash
echo package-name >> apps/aur/tools
```

Adicionar um serviço system:

```bash
echo example.service >> services/system
```

Linhas vazias e comentários iniciados por `#` são ignorados. Confirme sempre o nome correto na fonte escolhida.

## Checks

```bash
bash scripts/check
```

O checker valida estrutura, sintaxe Bash, ShellCheck, segredos óbvios, segurança do dry-run, Cloudflare Worker, listas de apps, serviços e documentação.

O GitHub Actions executa o mesmo checker, valida o Worker com Node.js e usa um dry-run portátil. O modo abaixo existe apenas para CI e só funciona com `--dry-run` ou `--plan`:

```bash
ARCHBOOT_CI=1 bash install.sh --plan
ARCHBOOT_CI=1 bash install.sh --dry-run --no-packages --no-services --no-ssh --no-github --no-codex
```

`ARCHBOOT_CI=1` não ignora segurança em uma instalação real: sem `--dry-run` ou `--plan`, o instalador aborta.

## Troubleshooting

Consulte [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) para diagnóstico curto de pacman lock, rede, sudo, Flatpak, AUR, Mullvad, GitHub, SSH, Codex, domínio e logs.

## Publish

```bash
bash scripts/github
```

O helper usa `gh`, executa os checks e cria ou envia o repositório sem usar `--force`.

## Uninstall notes

O archboot não promete desinstalação automática completa. Para desfazer partes da configuração:

* Remova `~/.codex/bin` dos arquivos de shell.
* Execute `npm config delete prefix`.
* Remova `~/.codex` manualmente se não precisar mais dele.
* Remova Flatpaks com `flatpak uninstall APP_ID`.
* Remova pacotes manualmente com pacman, paru ou yay.
* Desative serviços com `systemctl disable --now SERVICE` ou `systemctl --user disable --now SERVICE`.

## Security notes

* A instalação audit-first é recomendada.
* O repositório não contém tokens.
* `cloudflare/wrangler.toml` não é versionado.
* O pacman lock nunca é removido automaticamente.
* Pacotes não são removidos automaticamente.
* Arquivos SSH locais nunca são deletados pelo instalador.
* Logs usam permissões restritas e removem padrões comuns de tokens e chaves privadas.

## License

MIT.
