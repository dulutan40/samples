mod game;

use game::{Dir, Game, Phase};
use macroquad::prelude::*;

const CELL: f32 = 24.0;
const COLS: i32 = 24;
const ROWS: i32 = 18;
const STEP: f64 = 0.11;

fn window_conf() -> Conf {
    Conf {
        window_title: "Snake".to_owned(),
        window_width: (COLS as f32 * CELL) as i32,
        window_height: (ROWS as f32 * CELL + 40.0) as i32,
        high_dpi: true,
        ..Default::default()
    }
}

#[macroquad::main(window_conf)]
async fn main() {
    let mut game = Game::new(COLS, ROWS);
    let mut acc = 0.0_f64;
    let mut pending: Option<Dir> = None;

    loop {
        if is_key_pressed(KeyCode::Escape) {
            break;
        }

        if let Some(dir) = read_dir() {
            pending = Some(dir);
        }

        match game.phase {
            Phase::Ready | Phase::Over => {
                if is_key_pressed(KeyCode::Space) || is_key_pressed(KeyCode::Enter) {
                    game = Game::new(COLS, ROWS);
                    pending = None;
                    acc = 0.0;
                    game.phase = Phase::Playing;
                }
            }
            Phase::Playing => {
                acc += get_frame_time() as f64;
                while acc >= STEP {
                    acc -= STEP;
                    if let Some(dir) = pending.take() {
                        game.try_turn(dir);
                    }
                    game.step();
                }
            }
        }

        clear_background(Color::from_rgba(7, 8, 12, 255));
        draw_board(&game);
        draw_hud(&game);
        next_frame().await;
    }
}

fn read_dir() -> Option<Dir> {
    if is_key_pressed(KeyCode::Up) || is_key_pressed(KeyCode::W) {
        Some(Dir::Up)
    } else if is_key_pressed(KeyCode::Down) || is_key_pressed(KeyCode::S) {
        Some(Dir::Down)
    } else if is_key_pressed(KeyCode::Left) || is_key_pressed(KeyCode::A) {
        Some(Dir::Left)
    } else if is_key_pressed(KeyCode::Right) || is_key_pressed(KeyCode::D) {
        Some(Dir::Right)
    } else {
        None
    }
}

fn draw_board(game: &Game) {
    let board = Color::from_rgba(18, 20, 28, 255);
    draw_rectangle(0.0, 40.0, COLS as f32 * CELL, ROWS as f32 * CELL, board);

    let food = Color::from_rgba(244, 211, 94, 255);
    draw_rectangle(
        game.food.x as f32 * CELL + 3.0,
        40.0 + game.food.y as f32 * CELL + 3.0,
        CELL - 6.0,
        CELL - 6.0,
        food,
    );

    for (i, cell) in game.snake.iter().enumerate() {
        let t = i as f32 / game.snake.len().max(1) as f32;
        let color = Color::from_rgba(
            (60.0 + 100.0 * (1.0 - t)) as u8,
            (220.0 - 80.0 * t) as u8,
            (160.0 + 40.0 * (1.0 - t)) as u8,
            255,
        );
        draw_rectangle(
            cell.x as f32 * CELL + 1.0,
            40.0 + cell.y as f32 * CELL + 1.0,
            CELL - 2.0,
            CELL - 2.0,
            color,
        );
    }
}

fn draw_hud(game: &Game) {
    let ink = Color::from_rgba(232, 237, 247, 255);
    let muted = Color::from_rgba(139, 147, 167, 255);
    let accent = Color::from_rgba(60, 224, 200, 255);

    draw_text("SNAKE", 12.0, 26.0, 26.0, accent);
    draw_text(&format!("SCORE {}", game.score), 140.0, 26.0, 22.0, ink);

    match game.phase {
        Phase::Ready => {
            draw_text("SPACE to start — arrows / WASD to move", 12.0, 70.0, 20.0, muted);
        }
        Phase::Over => {
            let msg = format!("GAME OVER — score {} — SPACE to retry", game.score);
            draw_text(&msg, 12.0, 70.0, 20.0, ink);
        }
        Phase::Playing => {}
    }
}
