mod game;
mod maze;

use game::{Dir, Game, GhostMode, Phase};
use macroquad::prelude::*;
use maze::{Cell, TILE};

fn window_conf() -> Conf {
    let maze = maze::Maze::parse_level(0);
    let (w, h) = maze.pixel_size();
    Conf {
        window_title: "Hungry Emoji".to_owned(),
        window_width: w as i32,
        window_height: (h + 48.0) as i32,
        high_dpi: true,
        ..Default::default()
    }
}

#[macroquad::main(window_conf)]
async fn main() {
    let mut game = Game::new();

    loop {
        if is_key_pressed(KeyCode::Escape) {
            break;
        }
        if is_key_pressed(KeyCode::Space) || is_key_pressed(KeyCode::Enter) {
            match game.phase {
                Phase::Ready => game.begin(),
                Phase::LevelClear => game.advance_after_clear(),
                Phase::Won | Phase::Lost => game.retry(),
                Phase::Playing => {}
            }
        }

        if game.phase == Phase::Playing {
            if is_key_pressed(KeyCode::Up) || is_key_pressed(KeyCode::W) {
                game.queue_dir(Dir::Up);
            } else if is_key_pressed(KeyCode::Down) || is_key_pressed(KeyCode::S) {
                game.queue_dir(Dir::Down);
            } else if is_key_pressed(KeyCode::Left) || is_key_pressed(KeyCode::A) {
                game.queue_dir(Dir::Left);
            } else if is_key_pressed(KeyCode::Right) || is_key_pressed(KeyCode::D) {
                game.queue_dir(Dir::Right);
            }
            game.update(get_frame_time());
        }

        clear_background(Color::from_rgba(7, 8, 12, 255));
        draw_hud(&game);
        draw_maze(&game);
        for g in &game.ghosts {
            draw_ghost(g);
        }
        draw_hungry_emoji(&game);
        draw_banner(&game);
        next_frame().await;
    }
}

fn draw_hud(game: &Game) {
    let accent = Color::from_rgba(60, 224, 200, 255);
    let ink = Color::from_rgba(232, 237, 247, 255);
    draw_text("HUNGRY EMOJI", 12.0, 28.0, 26.0, accent);
    draw_text(
        &format!(
            "LVL {}/{}   SCORE {}   LIVES {}",
            game.level + 1,
            maze::LEVEL_COUNT,
            game.score,
            game.lives
        ),
        200.0,
        28.0,
        20.0,
        ink,
    );
}

fn draw_banner(game: &Game) {
    let muted = Color::from_rgba(139, 147, 167, 255);
    let ink = Color::from_rgba(232, 237, 247, 255);
    match game.phase {
        Phase::Ready => {
            draw_text(
                "SPACE to start — five mazes, one hungry emoji",
                12.0,
                56.0,
                18.0,
                muted,
            );
        }
        Phase::LevelClear => {
            let text = format!(
                "LEVEL {} CLEAR — SPACE for level {}",
                game.level + 1,
                game.level + 2
            );
            draw_text(&text, 12.0, 56.0, 18.0, ink);
        }
        Phase::Won => {
            draw_text(
                "ALL FIVE MAZES CLEARED — SPACE to feast again",
                12.0,
                56.0,
                18.0,
                ink,
            );
        }
        Phase::Lost => {
            draw_text("SO FULL… OF DEFEAT — SPACE to retry", 12.0, 56.0, 18.0, ink);
        }
        Phase::Playing => {}
    }
}

fn draw_maze(game: &Game) {
    let origin_y = 48.0;
    let wall = Color::from_rgba(40, 70, 180, 255);
    let pellet = Color::from_rgba(255, 220, 160, 255);
    let power = Color::from_rgba(255, 200, 80, 255);

    for y in 0..game.maze.rows {
        for x in 0..game.maze.cols {
            let px = x as f32 * TILE;
            let py = origin_y + y as f32 * TILE;
            match game.maze.get(x as i32, y as i32) {
                Cell::Wall => {
                    draw_rectangle(px + 1.0, py + 1.0, TILE - 2.0, TILE - 2.0, wall);
                }
                Cell::Pellet => {
                    draw_circle(px + TILE * 0.5, py + TILE * 0.5, 2.2, pellet);
                }
                Cell::Power => {
                    let pulse = 4.0 + (get_time() as f32 * 6.0).sin() * 1.2;
                    draw_circle(px + TILE * 0.5, py + TILE * 0.5, pulse, power);
                }
                Cell::Gate => {
                    draw_rectangle(
                        px + 2.0,
                        py + TILE * 0.45,
                        TILE - 4.0,
                        3.0,
                        Color::from_rgba(255, 180, 200, 255),
                    );
                }
                Cell::Empty => {}
            }
        }
    }
}

fn draw_hungry_emoji(game: &Game) {
    let origin_y = 48.0;
    let cx = game.player.x;
    let cy = origin_y + game.player.y;
    let r = TILE * 0.42;

    let chomp = (game.chomp.sin().abs() * 0.55 + 0.18).clamp(0.12, 0.75);
    let facing = game.player.dir.angle();

    let face = Color::from_rgba(255, 204, 77, 255);
    let mouth_void = Color::from_rgba(7, 8, 12, 255);

    draw_circle(cx, cy, r, face);

    let a0 = facing - chomp;
    let a1 = facing + chomp;
    draw_triangle(
        vec2(cx, cy),
        vec2(cx + a0.cos() * (r + 1.0), cy + a0.sin() * (r + 1.0)),
        vec2(cx + a1.cos() * (r + 1.0), cy + a1.sin() * (r + 1.0)),
        mouth_void,
    );

    // Eye sits on the top of the face for left/right (emoji orientation).
    let (ex, ey) = match game.player.dir {
        Dir::Left | Dir::Right => (cx + if game.player.dir == Dir::Left { -r * 0.12 } else { r * 0.12 }, cy - r * 0.42),
        Dir::Up => (cx + r * 0.22, cy - r * 0.12),
        Dir::Down => (cx + r * 0.22, cy + r * 0.05),
    };
    draw_circle(ex, ey, r * 0.17, WHITE);
    let pupil_dx = match game.player.dir {
        Dir::Left => -r * 0.04,
        Dir::Right => r * 0.04,
        Dir::Up => 0.0,
        Dir::Down => 0.0,
    };
    draw_circle(
        ex + pupil_dx,
        ey,
        r * 0.08,
        Color::from_rgba(40, 40, 50, 255),
    );

    let blush = Color::from_rgba(255, 140, 150, 90);
    let (bx, by) = match game.player.dir {
        Dir::Left => (cx - r * 0.42, cy + r * 0.2),
        Dir::Right => (cx + r * 0.42, cy + r * 0.2),
        _ => (cx - r * 0.4, cy + r * 0.25),
    };
    draw_circle(bx, by, r * 0.13, blush);
}

fn draw_ghost(ghost: &game::Ghost) {
    let origin_y = 48.0;
    let cx = ghost.actor.x;
    let cy = origin_y + ghost.actor.y;
    let body = match ghost.mode {
        GhostMode::Frightened => Color::from_rgba(80, 80, 255, 255),
        GhostMode::Eaten => Color::from_rgba(200, 200, 220, 120),
        GhostMode::Chase => Color::from_rgba(ghost.color[0], ghost.color[1], ghost.color[2], 255),
    };
    let r = TILE * 0.38;
    if ghost.mode == GhostMode::Eaten {
        draw_circle(cx - 4.0, cy - 2.0, 3.5, WHITE);
        draw_circle(cx + 4.0, cy - 2.0, 3.5, WHITE);
        draw_circle(cx - 3.0, cy - 2.0, 1.5, BLACK);
        draw_circle(cx + 5.0, cy - 2.0, 1.5, BLACK);
        return;
    }
    draw_circle(cx, cy - 2.0, r, body);
    draw_rectangle(cx - r, cy - 2.0, r * 2.0, r + 4.0, body);
    for i in 0..3 {
        let fx = cx - r + i as f32 * (r * 2.0 / 3.0) + r / 3.0;
        draw_circle(fx, cy + r + 1.0, r / 3.0, body);
    }
    draw_circle(cx - 4.0, cy - 4.0, 3.5, WHITE);
    draw_circle(cx + 4.0, cy - 4.0, 3.5, WHITE);
    draw_circle(cx - 3.0, cy - 4.0, 1.6, BLACK);
    draw_circle(cx + 5.0, cy - 4.0, 1.6, BLACK);
}
