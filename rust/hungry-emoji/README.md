# Hungry Emoji

A compact **Pac-Man** tribute in Rust + [macroquad](https://github.com/not-fl3/macroquad). You play a sideways hungry-face emoji: yellow cheek, chomping wedge mouth, one emoji eye. Clear pellets, gulp power dots, and stay away from the ghosts — unless they're blue.

## Run

```bash
cd rust/hungry-emoji
cargo run --release
```

## Controls

| Key | Action |
| --- | --- |
| Arrows / WASD | Steer |
| Space / Enter | Start or retry |
| Esc | Quit |

## Layout

```text
src/
  main.rs     drawing (including the hungry emoji)
  game.rs     movement, ghosts, scoring, lives
  maze.rs     maze data + walkability
```

## Why Rust

Fits the same desktop arcade lane as `snake` and `asteroids`: one binary, clear sim/render split, and a recognizable classic with a small original twist (the emoji face).
