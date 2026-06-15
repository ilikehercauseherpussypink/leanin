# Cloudflare Worker

O Worker publica o `install.sh` do GitHub por um domínio curto, sem alterar o conteúdo e sem executar lógica de instalação.

* Custom domain: `https://shelies.org`
* Worker URL: `https://archboot.jocaluvero.workers.dev`
* Upstream: `https://github.com/ilikehercauseherpussypink/archboot`

O Worker não contém segredos. `OWNER`, `REPO` e `BRANCH` vêm das variáveis do Worker ou dos defaults definidos em `worker.js`. Query strings não alteram esses valores.

## Endpoints

Health check:

```bash
curl -fsSL https://shelies.org/health
```

Validar o script servido:

```bash
curl -fsSL https://shelies.org -o /tmp/archboot-install.sh
head -n 20 /tmp/archboot-install.sh
```

Dry-run:

```bash
curl -fsSL https://shelies.org | bash -s -- --dry-run
```

Instalação direta:

```bash
curl -fsSL https://shelies.org | bash
```

O mesmo script também está disponível em `/install.sh` e pela URL direta do Worker.

## Deploy with Wrangler

Instale e autentique o Wrangler:

```bash
npm install -g wrangler
wrangler login
```

Crie a configuração local:

```bash
cp cloudflare/wrangler.toml.example cloudflare/wrangler.toml
```

Edite `OWNER`, `REPO`, `BRANCH` e `pattern`. Depois publique:

```bash
cd cloudflare
wrangler deploy
```

`cloudflare/wrangler.toml` é ignorado pelo Git. O arquivo `.example` permanece como modelo versionado.

## Deploy with Cloudflare Dashboard

1. Crie ou abra um Worker no dashboard da Cloudflare.
2. Cole o conteúdo de `worker.js` no editor.
3. Configure `OWNER`, `REPO` e `BRANCH` em Variables and Secrets como texto comum.
4. Faça o deploy.
5. Associe `shelies.org` em Settings, Domains & Routes, Custom Domains.

Nenhuma secret é necessária para acessar um repositório público.
