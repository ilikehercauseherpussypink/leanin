# Cloudflare Worker

The Worker serves `install.sh` from GitHub through a short domain. It does not modify the script or run installer logic.

* Custom domain: `https://shelies.org`
* Upstream repository: `https://github.com/ilikehercauseherpussypink/leanin`

The Worker has no secrets. `OWNER`, `REPO`, and `BRANCH` come from Worker variables or the defaults in `worker.js`. Query strings cannot change them.

Keep the Worker `REPO` variable aligned with the upstream repository before deploying.

## Endpoints

```bash
curl -fsSL https://shelies.org/health
curl -fsSL https://shelies.org -o /tmp/leanin-install.sh
head -n 20 /tmp/leanin-install.sh
curl -fsSL https://shelies.org | bash -s -- --dry-run
curl -fsSL https://shelies.org | bash
```

The same script is also available at `/install.sh`.

## Deploy with Wrangler

```bash
npm install -g wrangler
wrangler login
cp cloudflare/wrangler.toml.example cloudflare/wrangler.toml
cd cloudflare
wrangler deploy
```

Edit `OWNER`, `REPO`, `BRANCH`, and `pattern` in `wrangler.toml` first. The real `cloudflare/wrangler.toml` is ignored by Git; the example file remains versioned.

## Deploy with the Cloudflare Dashboard

1. Create or open a Worker in the Cloudflare dashboard.
2. Paste `worker.js` into the editor.
3. Set `OWNER`, `REPO`, and `BRANCH` as plain Worker variables.
4. Deploy the Worker.
5. Add `shelies.org` under Settings, Domains & Routes, Custom Domains.

No secret is required for a public repository.
