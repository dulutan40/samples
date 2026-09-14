# Last to Tap

Multiplayer nerve game: after the round starts, tap whenever you want — but the **last** legal tap before a hidden cutoff wins. The cutoff is drawn uniformly between **10 and 25 seconds**. After you tap, you cannot tap again for **1 second**.

**Stack:** Flutter client (iOS, Android, macOS, web) + a small Dart WebSocket server so every platform can share a room.

## Modes

| Mode | Use |
| --- | --- |
| **Online room** | Create/join with a 4-letter code. Host starts. Works across devices on the same server. |
| **Local party** | 2–8 buttons on one screen — couch play, no server. |

The exact end time is **not** shown during a round (that would spoil the game).

## Run the server

```bash
cd dart/last-to-tap/server
dart pub get
dart run bin/server.dart
# listens on ws://0.0.0.0:3471  (override with PORT or arg)
```

## Run the client

```bash
cd dart/last-to-tap
flutter pub get
flutter run -d chrome          # web
flutter run -d macos           # macOS
flutter run                    # attached iOS / Android
```

Default server URLs:

- Web / macOS / iOS simulator: `ws://127.0.0.1:3471`
- Android emulator: `ws://10.0.2.2:3471`
- Override in the Online screen, or compile with `--dart-define=LTT_SERVER=ws://YOUR_LAN_IP:3471`

## Rules (authoritative on the server for online)

1. Host starts when at least two players are connected.
2. Hidden timer ∈ [10s, 25s] uniform.
3. Tap sets your last-tap timestamp; then 1s cooldown.
4. When the timer fires, the player with the latest tap wins (or nobody if no taps).

## Layout

```text
lib/               Flutter UI + local engine + WS client
server/            Authoritative room host (shelf + WebSocket)
```

## Why Flutter + Dart server

One UI codebase covers iOS, Android, macOS, and web. The server stays in Dart so the sample is easy to run with the Flutter SDK alone, and timing/cooldowns cannot be forged by a client.

## Future ideas

Not implemented yet — product / monetization notes for a shipped build.

### Freemium + premium

- **Free tier:** ads in the experience.
- **Premium (subscription):** no ads.

### Tokens (IAP)

- Players buy tokens with real money: **$1 = 100 tokens**.
- Free players can also earn tokens by watching ads: **1 ad = 1 token**.

### VIP rooms (token stakes)

- VIP rooms are entered with tokens and play for token payouts (real-money value via the token economy).
- **Antes / room tiers:** `1` · `10` · `100` · `1_000` · `10_000` tokens.
- Each round the **dealer takes 1 token**; the **remaining pot pays out to the winner**.
- Example: 4 players in a 10-token ante room → pot 40 → dealer keeps 1 → winner receives 39.