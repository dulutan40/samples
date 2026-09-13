# Guess the Number

React Native sample (Expo, TypeScript). A player thinks of a number; the other tries to find it from higher / lower hints.

## Modes

**One player** — You play the computer. The number is between 0 and 100, and the guesser has **6** tries.

- *I am thinking of a number* — The computer guesses (binary search). After each try you say whether the guess is lower, higher, or correct.
- *I will guess* — The computer picks a secret. After each of your guesses it tells you if you are too low, too high, or correct.

Six guesses cannot guarantee a win over 101 possibilities, so the computer can lose even with perfect play.

**Two players, offline** — Same device. Choose 0–100, 0–1,000, or 0–10,000. One player looks away while the other enters a secret, then guessing has **no limit**.

**Two players, online** — Each person uses their own device. One host creates a room and gets a 4-digit passcode; the other joins with that code. The room **locks at two players**. The host then picks the range and who thinks. Same rules as offline (no guess limit).

## Run the app

```bash
npm install
npm start
```

Then open it in iOS, Android, or the web (`npm run web`).

## Run an online match

Start the room server first. It must be reachable by both devices:

```bash
npm run server
```

It listens on `http://0.0.0.0:3456` (override with `PORT`).

- Two browsers on this computer: leave the app’s server field as `http://localhost:3456`.
- A phone on the same Wi-Fi: set the field to `http://<your-computer-lan-ip>:3456`.

On macOS you can print that address with `ipconfig getifaddr en0`.

To check the room protocol without the UI:

```bash
npm run server
npm run test:server
```

## Project layout

```text
App.tsx                 Screen switcher
src/game/engine.ts      Pure guess logic (no UI)
src/screens/            One-player, offline, and online flows
src/online/             Socket.IO client
server/index.js         In-memory room server
```
