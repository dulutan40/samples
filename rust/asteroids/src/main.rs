mod game;
mod math;

use game::{Game, Phase};
use macroquad::prelude::*;

fn window_conf() -> Conf {
    Conf {
        window_title: "Asteroids".to_owned(),
        window_width: 900,
        window_height: 700,
        high_dpi: true,
        ..Default::default()
    }
}

#[macroquad::main(window_conf)]
async fn main() {
    let mut game = Game::new(screen_width(), screen_height());

    loop {
        if is_key_pressed(KeyCode::Escape) {
            break;
        }

        let w = screen_width();
        let h = screen_height();
        game.resize(w, h);
        let dt = get_frame_time();

        match game.phase {
            Phase::Ready | Phase::Over | Phase::Won => {
                if is_key_pressed(KeyCode::Space) || is_key_pressed(KeyCode::Enter) {
                    game = Game::new(w, h);
                    game.phase = Phase::Playing;
                }
            }
            Phase::Playing => {
                let left = is_key_down(KeyCode::Left) || is_key_down(KeyCode::A);
                let right = is_key_down(KeyCode::Right) || is_key_down(KeyCode::D);
                let thrust = is_key_down(KeyCode::Up) || is_key_down(KeyCode::W);
                let shoot = is_key_pressed(KeyCode::Space);
                game.input(dt, left, right, thrust, shoot);
                game.update(dt);
            }
        }

        clear_background(Color::from_rgba(5, 6, 10, 255));
        draw_stars(w, h);
        draw_world(&game);
        draw_hud(&game);
        next_frame().await;
    }
}

fn draw_stars(w: f32, h: f32) {
    let star = Color::from_rgba(90, 100, 130, 180);
    for i in 0..60 {
        let x = ((i * 97) % 1000) as f32 / 1000.0 * w;
        let y = ((i * 53) % 1000) as f32 / 1000.0 * h;
        draw_circle(x, y, if i % 5 == 0 { 1.6 } else { 1.0 }, star);
    }
}

fn v(p: math::Vec2) -> Vec2 {
    vec2(p.x, p.y)
}

fn draw_world(game: &Game) {
    let rock = Color::from_rgba(180, 190, 210, 255);
    for a in &game.asteroids {
        draw_poly_lines(
            a.pos.x,
            a.pos.y,
            a.sides,
            a.radius,
            a.angle.to_degrees(),
            2.0,
            rock,
        );
    }

    let shot = Color::from_rgba(244, 211, 94, 255);
    for b in &game.bullets {
        draw_circle(b.pos.x, b.pos.y, 2.5, shot);
    }

    if game.phase == Phase::Playing || game.phase == Phase::Ready {
        let ship = Color::from_rgba(60, 224, 200, 255);
        let nose = game.ship.pos + math::from_angle(game.ship.angle) * 16.0;
        let left = game.ship.pos + math::from_angle(game.ship.angle + 2.5) * 12.0;
        let right = game.ship.pos + math::from_angle(game.ship.angle - 2.5) * 12.0;
        draw_triangle_lines(v(nose), v(left), v(right), 2.0, ship);

        if game.thrusting {
            let flame = Color::from_rgba(255, 120, 80, 255);
            let back = game.ship.pos + math::from_angle(game.ship.angle + std::f32::consts::PI) * 10.0;
            draw_circle(back.x, back.y, 3.0, flame);
        }
    }
}

fn draw_hud(game: &Game) {
    let ink = Color::from_rgba(232, 237, 247, 255);
    let muted = Color::from_rgba(139, 147, 167, 255);
    let accent = Color::from_rgba(60, 224, 200, 255);

    draw_text("ASTEROIDS", 16.0, 28.0, 28.0, accent);
    draw_text(
        &format!("SCORE {}   LIVES {}", game.score, game.lives),
        180.0,
        28.0,
        22.0,
        ink,
    );

    let tip = match game.phase {
        Phase::Ready => Some("SPACE to launch — arrows / WASD turn & thrust, SPACE fires"),
        Phase::Over => Some("SHIP LOST — SPACE to try again"),
        Phase::Won => Some("FIELD CLEAR — SPACE for another wave"),
        Phase::Playing => None,
    };
    if let Some(text) = tip {
        draw_text(text, 16.0, 56.0, 18.0, muted);
    }
}
