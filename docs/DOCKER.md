# Docker

Devbook runs as a set of containers with Docker Compose: the Rails app, the
Solid Queue background job worker, the Tailwind watcher, and PostgreSQL with
`pgvector`.

This runs the app in **development mode** inside the container: code reloading,
Rails error pages, and the Tailwind watcher all work, and the working tree is
bind-mounted so edits on the host apply immediately without a rebuild.

For production deployment see [Kamal](#production) at the bottom.

## Quick start

```sh
docker compose up -d --build
docker compose logs -f web
```

The app is then on <http://localhost:3008>. The first boot creates the
databases, loads the schema, and runs `db:prepare` on boot.

To configure your database password before the first boot, set it in `.env`:

```sh
POSTGRES_PASSWORD=choose-a-database-password
```

## Starting on boot

Every service uses `restart: unless-stopped`, so once the stack has been
created, Docker starts it again whenever the daemon starts, including at boot.

The stack does not come back on its own after `docker compose down`, because
that removes the containers. Start it again with `docker compose up -d`.

## Services

| Service | Runs | Notes |
| --- | --- | --- |
| `db` | `pgvector/pgvector:pg18` | Data in the `pg_data` volume. Preconfigured with PostgreSQL and the `vector` extension. Not published to the host by default. |
| `web` | `bin/rails server` | Serves the app on port 3008 and runs `db:prepare` on boot. |
| `jobs` | `bin/jobs` | Solid Queue background job worker. |
| `css` | `bin/rails tailwindcss:watch[always]` | Rebuilds `app/assets/builds/tailwind.css` when stylesheets change. The `always` argument puts Tailwind in polling mode, which keeps the watcher alive on a bind-mounted filesystem. |

All three Ruby services share the same image (`Dockerfile.dev`) and the same
bind mount, so a code change applies to all of them. Only `web` touches the
database on boot; `jobs` waits for the web health check so the two never race to
create or migrate the same database.

All containers are configured with `restart: unless-stopped`, so the Docker
daemon automatically starts the entire stack upon system boot or reboot.

## Persistence

Everything that matters survives restarts, `docker compose down`, container
recreates, and image rebuilds:

- **Database** — the named volume `devbook_pg_data` (mapped as `pg_data`).
- **Uploaded files** — `storage/` in the working tree, shared through the bind
  mount (`config.active_storage.service = :local`).

The volume is only destroyed by an explicit request:

```sh
docker compose down        # keeps the database
docker compose down -v     # deletes the database
```

### Why the volume is mounted at `/var/lib/postgresql`

PostgreSQL 18 stores data under `/var/lib/postgresql/<major>/docker`, so the
volume is mounted at the parent directory (`/var/lib/postgresql`). Mounting the
older `/var/lib/postgresql/data` path would leave the actual database files in the
container layer, causing data loss upon container recreation.

### Backup and restore

`--no-owner` matters: the dump is restored by a different role than the one
that owns the local database, and ownership statements would otherwise fail.

```sh
docker compose exec db pg_dump -U postgres --no-owner devbook_development > backup.sql
docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d devbook_development < backup.sql
```

## Configuration

### Database connection

`config/database.yml` reads the standard libpq variables:

| Variable | In Docker | On the host |
| --- | --- | --- |
| `PGHOST` | `db` | unset, so the local unix socket is used |
| `PGUSER` | `postgres` | unset, so the current OS user is used |
| `PGPASSWORD` | `POSTGRES_PASSWORD` from `.env` | unset |

All three are unset by default, so running `bin/dev` on the host keeps using
your local PostgreSQL exactly as before.

### Accessing over Tailscale and other devices

The web service binds to `0.0.0.0:3008`. Rails in `development.rb` is preconfigured
to permit:
- Any Tailscale CGNAT IPv4 address (`100.64.0.0/10`)
- Any Tailscale IPv6 address (`fd7a:115c:a1e0::/48`)
- Tailscale MagicDNS hostnames (`*.ts.net`)
- Local network hostnames (e.g. `hostname.local`)

You can access Devbook from any device on your Tailscale network:
```sh
http://<your-tailscale-ip>:3008
# e.g.: http://100.x.y.z:3008 or http://<device-name>.ts.net:3008
```

For custom external domains (such as ngrok or Cloudflare tunnels), set
`RAILS_DEVELOPMENT_HOSTS` in `.env`:

```sh
RAILS_DEVELOPMENT_HOSTS=devbook.your-domain.com
```

## Everyday commands

```sh
docker compose logs -f web         # follow the app logs
docker compose restart web         # restart after an environment change
docker compose up -d --build       # rebuild after a Gemfile change
docker compose run --rm web bash   # shell in the container
```

Rails console and database console:

```sh
docker compose exec web bin/rails console
docker compose exec db psql -U postgres -d devbook_development
```

Run tests inside the container:

```sh
docker compose exec web bin/rails test
```

## Importing existing local data

To start from a database you already have on the host rather than a fresh
one, dump it and restore it into the container. Stop the app first so nothing
writes while the import runs.

```sh
# On the host
pg_dump --no-owner --no-privileges -d devbook_development > backup.sql

# Into the container
docker compose up -d db
docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d devbook_development < backup.sql
docker compose up -d
```

## Production

The default `Dockerfile` and `config/deploy.yml` target production and are
unchanged by any of this. Production runs in `RAILS_ENV=production` with Kamal:

```sh
bin/kamal setup
bin/kamal deploy
```
