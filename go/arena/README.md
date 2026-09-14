# Arena

Multiplayer top-down duel in **Go**. The server owns the simulation (movement, bullets, hits, respawns) and streams snapshots over WebSockets. A tiny canvas client is embedded in the same binary.

## Run

```bash
cd go/arena
go run .
```

Open [http://127.0.0.1:3470](http://127.0.0.1:3470) in two browser tabs (or two machines on your LAN with `-addr 0.0.0.0:3470`).

```bash
go test ./...
go build -o bin/arena .
./bin/arena
# or: ./bin/arena -addr 0.0.0.0:3470
```

## Controls

| Input | Action |
| --- | --- |
| WASD / arrows | Move |
| Mouse | Aim |
| Click or Space | Fire |

## Layout

```text
main.go             HTTP server + embedded client
internal/game/      authoritative world + tests
internal/server/    WebSocket hub
web/                canvas client (embedded)
```

## Why this sample

Shows Go for concurrent networking: one tick loop, per-client read/write pumps, and an authoritative game state clients cannot cheat by inventing hits. Complements the JavaScript Socket.io samples with a compiled server and a single deployable binary.
