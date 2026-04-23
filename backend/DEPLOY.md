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
- CORS allows public `GET` reads plus `POST /interactions` so the iOS app can
  send batched personalization signals.
- Rate limits: 60 req/min/IP on `/articles` and `/feed`, 120 req/min/IP on
  `/interactions`, 30 req/min/IP on `/health`.
- `min_machines_running = 0` means Fly will stop the machine when idle; the
  first request after idle takes a couple of seconds to wake it. The API now
  schedules a refresh when stale content is requested after wake. If you want
  always-on scheduled refreshes, bump this to `1`.
