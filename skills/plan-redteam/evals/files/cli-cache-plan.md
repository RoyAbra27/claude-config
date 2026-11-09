# CLI response cache - design

**User decision (fixed):** the cache is a single SQLite file at `~/.mytool/cache.db`. No Redis, no server. Decided after discussion; do not revisit.

**Goal:** cache GET responses from the vendor API for 10 minutes so repeated `mytool status` calls are fast. One user per machine, a few hundred calls/day.

## Design
- Table `cache(key text primary key, body blob not null, expires_at integer not null)`; key = method + full URL.
- On read: `select body from cache where key = ? and expires_at > unixepoch()`.
- On write: `insert ... on conflict(key) do update set body = excluded.body, expires_at = excluded.expires_at`.
- Responses with status != 200 are not cached.
- `mytool cache clear` deletes the file.

## Tasks
1. `cache.py` with `get(key) -> bytes | None` and `put(key, body, ttl_s=600)`; tests: hit, miss, expiry (monkeypatched clock), non-200 not stored.
2. Wire into the HTTP client; test that two `status` calls make one network request.
