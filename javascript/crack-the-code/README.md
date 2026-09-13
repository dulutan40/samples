# Crack the Code

React Native sample (Expo, TypeScript). Mastermind with digits: one player hides a code, the other scores each guess with pluses and minuses.

## Rules

The secret is a **3, 4, or 5-digit** code. Digits cannot repeat. Zero may be first.

After each guess the whole code is scored — not each slot:

- **+1** for each digit that is correct and in the right place
- **−1** for each digit that is in the code but in the wrong place

Example: secret `12345`, guess `42063` → **+1 −2** (the 2 is exact; 4 and 3 are present but shifted).

You can switch the marks between **numeric** (`+1 −2`) and **colors**:

- green = plus
- yellow = minus
- red = a digit that is not in the code at all

The colored pips are grouped counts. They do not line up with individual slots.

## Modes

**One player** — Play the computer. Choose who thinks. The guesser has 8 tries (3 digits), 10 (4 digits), or 12 (5 digits).

**Two players, offline** — Same device. Choose length and who thinks. No guess limit.

**Two players, online** — Create a room and share a 4-digit passcode, or join with that code. The room locks at two players. The host then picks length and roles.

Length can be switched on the home, role, and setup screens before a round starts.

## Run the app

```bash
npm install
npm start
```

Then open it in iOS, Android, or the web (`npm run web`).

## Run an online match

```bash
npm run server
```

The room server listens on `http://0.0.0.0:3457` (override with `PORT`).

- Two browsers on this computer: leave the app’s server field as `http://localhost:3457`.
- A phone on the same Wi-Fi: set the field to `http://<your-computer-lan-ip>:3457`.

```bash
npm run server
npm run test:server
```
