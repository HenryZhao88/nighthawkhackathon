# Deploying the backend to Fly.io

One-time setup:

```bash
brew install flyctl
fly auth login

cd backend
fly launch --no-deploy --copy-config --name newshawk-api
#   - accept the Dockerfile it finds
#   - say NO to Postgres / Redis / Upstash
#   - when it asks about a volume, skip (we create one manually below)

# Persistent volume for the SQLite file
fly volumes create newshawk_data --size 1 --region iad

# Your OpenAI key — never committed, only ever lives on Fly's secret store
fly secrets set OPENAI_API_KEY=sk-...

fly deploy
```

After `fly deploy` finishes it prints a URL like `https://newshawk-api.fly.dev`.
Paste that into `NewsService.baseURL` in the iOS app.

## Updating

```bash
cd backend
fly deploy
```

The volume (and the DB) persists across deploys.

## Useful commands

```bash
fly status
fly logs
fly ssh console                # shell into the machine
fly secrets list               # names only, never values
```

## Notes

- `articles.db` (and WAL/SHM) live on `/data` inside the container, which is the
  mounted Fly volume. Do not store them anywhere else or they'll be wiped on
  deploy.
- Only `GET` is allowed through CORS. There are no write endpoints — the API is
  read-only to the world.
- Rate limits: 60 req/min/IP on `/articles`, 30 req/min/IP on `/health`.
- `min_machines_running = 0` means Fly will stop the machine when idle; the
  first request after idle takes a couple of seconds to wake it. If you want
  always-on, bump to `1`.
