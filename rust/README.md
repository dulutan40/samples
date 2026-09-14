# Rust samples

Desktop games in Rust with [macroquad](https://github.com/not-fl3/macroquad).

| Project | What it is |
| --- | --- |
| [`snake`](snake) | Grid snake — eat, grow, don't crash |
| [`asteroids`](asteroids) | Thrust, shoot, split rocks |
| [`hungry-emoji`](hungry-emoji) | Pac-Man tribute — sideways hungry emoji, five mazes |

## Prerequisites

```bash
# https://rustup.rs
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Run

```bash
cd snake && cargo run --release
cd asteroids && cargo run --release
cd hungry-emoji && cargo run --release
```

```bash
cargo test
```
