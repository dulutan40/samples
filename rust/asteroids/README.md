# Asteroids

Arcade asteroids in **Rust** + [macroquad](https://github.com/not-fl3/macroquad). Thrust, turn, shoot. Large rocks split twice. Three lives. Clear the field to win the wave.

## Run

```bash
cd rust/asteroids
cargo run --release
```

## Controls

| Key | Action |
| --- | --- |
| Left / Right or A / D | Turn |
| Up / W | Thrust |
| Space | Fire (also starts / restarts) |
| Esc | Quit |

## Layout

```text
src/
  main.rs     window loop, input, drawing
  game.rs     ship, bullets, rocks, collisions, tests
  math.rs     tiny Vec2 helpers (no extra math crate)
```

## Why this sample

Shows Rust for real-time simulation: wrapping space, velocity, projectile lifetime, and hierarchical rock splitting — still a small, readable crate.
