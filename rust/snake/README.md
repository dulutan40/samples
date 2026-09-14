# Snake

Classic grid snake in **Rust** + [macroquad](https://github.com/not-fl3/macroquad). Eat the gold squares, grow, stay on the board, don't bite yourself.

## Run

```bash
cd rust/snake
cargo run --release
```

## Controls

| Key | Action |
| --- | --- |
| Arrows / WASD | Turn |
| Space / Enter | Start or retry |
| Esc | Quit |

## Layout

```text
src/
  main.rs     window loop, input, drawing
  game.rs     grid rules, scoring, tests
```

## Why this sample

Shows a small Rust binary with clear separation between simulation (`game`) and presentation (`main`), plus unit tests for core rules — no engine boilerplate beyond a thin 2D layer.
