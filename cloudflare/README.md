# Cloudflare Worker

Este Worker serve o `install.sh` diretamente do GitHub por um dominio curto. O GitHub continua sendo a fonte real; o Worker nao executa instalacao, nao altera o script e nao usa segredos.

## Preparacao

Instale o Wrangler, se necessario:

```bash
npm install -g wrangler
```

Autentique no Cloudflare:

```bash
wrangler login
```

Crie a configuracao local:

```bash
cp cloudflare/wrangler.toml.example cloudflare/wrangler.toml
```

Edite `OWNER`, `REPO`, `BRANCH` e `pattern`. O `pattern` deve ser o dominio real que sera associado ao Worker.

## Deploy

```bash
cd cloudflare
wrangler deploy
```

## Testes

```bash
curl -fsSL https://DOMINIO_CURTO/health
curl -fsSL https://DOMINIO_CURTO | head
curl -fsSL https://DOMINIO_CURTO/install.sh | head
```

## Uso

Instalacao direta:

```bash
curl -fsSL https://DOMINIO_CURTO | bash
```

Auditoria antes da execucao:

```bash
curl -fsSL https://DOMINIO_CURTO -o install.sh
less install.sh
bash install.sh
```

O `install.sh` obtido pelo Worker mantem o fluxo self-bootstrapping e baixa o tarball completo do GitHub quando `lib/` e `apps/` nao estao disponiveis localmente.
