# ti-openctio

OpenCTI threat-intel stack. The official OpenCTI compose is vendored **verbatim**; our connectors live beside it and are wired in with Compose's [`include`](https://docs.docker.com/compose/how-tos/multiple-compose-files/include/).

```
compose.yaml                      # only `include:` — no services of its own
opencti/                          # unmodified upstream (OpenCTI-Platform/docker)
  docker-compose.yml  rabbitmq.conf  .env.sample
connectors/
  external-import/                # alienvault (OTX) malpedia mandiant cisa-kev threatfox urlhaus abuseipdb-blacklist
  enrichment/                     # virustotal shodan abuseipdb
.env.template                     # source of truth for .env
scripts/
  generate-env.sh                 # .env generator
  fetch-upstream.sh               # refresh ./opencti from GitHub
```

## Quick start

```bash
make env                # creates .env: random secrets + a UUID per connector + empty API-key slots
$EDITOR .env            # fill the keys for connectors you want
make up
```

OpenCTI: http://localhost:8080 — login `OPENCTI_ADMIN_EMAIL` / `OPENCTI_ADMIN_PASSWORD` from `.env`.

## `.env` generation

`scripts/generate-env.sh` renders `.env` from `.env.template`:

| template value | result |
|---|---|
| `@uuid` | UUIDv4 (connector IDs, admin token) |
| `@hex32` / `@base64` / `@pass` | random secrets |
| *(empty)* | placeholder for an API key you fill in |

It is idempotent: values already set in `.env` are kept, so adding a connector to the template and re-running only adds the new variables. `--force` regenerates everything. The script lists API keys still empty.

## Enabling connectors

Our connectors use Compose **profiles**, so ones without credentials never crash-loop. In `.env`:

```bash
COMPOSE_PROFILES=connectors                      # all of them
COMPOSE_PROFILES=alienvault,malpedia,cisa-kev    # or pick
```

| profile | connector | credential |
|---|---|---|
| `alienvault` | AlienVault OTX | `ALIENVAULT_API_KEY` |
| `malpedia` | Malpedia | `MALPEDIA_AUTH_KEY` (optional) |
| `mandiant` | Mandiant / GTI | `MANDIANT_API_V4_KEY_ID`, `_KEY_SECRET` |
| `cisa-kev` | CISA KEV | — |
| `threatfox` | abuse.ch ThreatFox | — |
| `urlhaus` | abuse.ch URLhaus | — |
| `abuseipdb-blacklist` | AbuseIPDB blacklist | `ABUSEIPDB_API_KEY` |
| `virustotal` | VirusTotal enrichment | `VIRUSTOTAL_TOKEN` |
| `shodan` | Shodan enrichment | `SHODAN_TOKEN` |
| `abuseipdb` | AbuseIPDB enrichment | `ABUSEIPDB_API_KEY` |

Enrichment connectors have `CONNECTOR_AUTO=false` to protect API quotas; trigger them manually or flip it per connector.

## Adding a connector

1. Add `connectors/<kind>/<name>.yml` (copy any existing one; give it a `profiles:` entry).
2. Add an `include` entry in `compose.yaml`.
3. Add its `CONNECTOR_<NAME>_ID=@uuid` and key placeholders to `.env.template`, then `make env`.

## Updating upstream

`make upstream` (or `scripts/fetch-upstream.sh <git-ref>`) overwrites `opencti/` with the official files. Never edit them by hand — put changes in `connectors/` or a compose override.

## Notes

- `include` resolves each file relative to its own directory, so upstream's `./rabbitmq.conf` mount works unchanged. Duplicate service names across included files are an error, not a merge.
- `xtm-composer` (upstream) mounts `/var/run/docker.sock`; `COMPOSE_PROJECT_NAME` in `.env` must stay set because upstream derives its network name from it.
