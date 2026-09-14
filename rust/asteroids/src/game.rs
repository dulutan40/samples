use crate::math::{self, Vec2};
use rand::Rng;

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Phase {
    Ready,
    Playing,
    Over,
    Won,
}

pub struct Ship {
    pub pos: Vec2,
    pub vel: Vec2,
    pub angle: f32,
}

pub struct Bullet {
    pub pos: Vec2,
    pub vel: Vec2,
    pub life: f32,
}

pub struct Asteroid {
    pub pos: Vec2,
    pub vel: Vec2,
    pub radius: f32,
    pub angle: f32,
    pub spin: f32,
    pub sides: u8,
    pub kind: u8,
}

pub struct Game {
    pub width: f32,
    pub height: f32,
    pub ship: Ship,
    pub bullets: Vec<Bullet>,
    pub asteroids: Vec<Asteroid>,
    pub score: u32,
    pub lives: u32,
    pub phase: Phase,
    pub thrusting: bool,
    cooldown: f32,
    invuln: f32,
}

impl Game {
    pub fn new(width: f32, height: f32) -> Self {
        let mut game = Self {
            width,
            height,
            ship: Ship {
                pos: Vec2::new(width * 0.5, height * 0.5),
                vel: Vec2::ZERO,
                angle: -std::f32::consts::FRAC_PI_2,
            },
            bullets: Vec::new(),
            asteroids: Vec::new(),
            score: 0,
            lives: 3,
            phase: Phase::Ready,
            thrusting: false,
            cooldown: 0.0,
            invuln: 0.0,
        };
        game.spawn_wave(4);
        game
    }

    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width.max(1.0);
        self.height = height.max(1.0);
    }

    pub fn input(&mut self, dt: f32, left: bool, right: bool, thrust: bool, shoot: bool) {
        if left {
            self.ship.angle -= 3.6 * dt;
        }
        if right {
            self.ship.angle += 3.6 * dt;
        }
        self.thrusting = thrust;
        if thrust {
            self.ship.vel += math::from_angle(self.ship.angle) * 220.0 * dt;
        }
        if shoot && self.cooldown <= 0.0 {
            let dir = math::from_angle(self.ship.angle);
            self.bullets.push(Bullet {
                pos: self.ship.pos + dir * 18.0,
                vel: self.ship.vel + dir * 420.0,
                life: 1.1,
            });
            self.cooldown = 0.18;
        }
    }

    pub fn update(&mut self, dt: f32) {
        if self.phase != Phase::Playing {
            return;
        }

        self.cooldown = (self.cooldown - dt).max(0.0);
        self.invuln = (self.invuln - dt).max(0.0);

        self.ship.vel *= 0.992;
        self.ship.pos += self.ship.vel * dt;
        wrap(&mut self.ship.pos, self.width, self.height);

        for b in &mut self.bullets {
            b.pos += b.vel * dt;
            wrap(&mut b.pos, self.width, self.height);
            b.life -= dt;
        }
        self.bullets.retain(|b| b.life > 0.0);

        for a in &mut self.asteroids {
            a.pos += a.vel * dt;
            a.angle += a.spin * dt;
            wrap(&mut a.pos, self.width, self.height);
        }

        self.resolve_shots();
        self.resolve_crashes();

        if self.asteroids.is_empty() {
            self.phase = Phase::Won;
        }
    }

    fn resolve_shots(&mut self) {
        let mut splits = Vec::new();
        let mut hit_rocks = Vec::new();
        let mut hit_shots = Vec::new();

        for (bi, b) in self.bullets.iter().enumerate() {
            for (ai, a) in self.asteroids.iter().enumerate() {
                if math::dist(b.pos, a.pos) <= a.radius {
                    hit_shots.push(bi);
                    hit_rocks.push(ai);
                    self.score += match a.kind {
                        0 => 20,
                        1 => 50,
                        _ => 100,
                    };
                    splits.extend(split_asteroid(a));
                    break;
                }
            }
        }

        hit_shots.sort_unstable();
        hit_shots.dedup();
        for i in hit_shots.into_iter().rev() {
            if i < self.bullets.len() {
                self.bullets.remove(i);
            }
        }
        hit_rocks.sort_unstable();
        hit_rocks.dedup();
        for i in hit_rocks.into_iter().rev() {
            if i < self.asteroids.len() {
                self.asteroids.remove(i);
            }
        }
        self.asteroids.extend(splits);
    }

    fn resolve_crashes(&mut self) {
        if self.invuln > 0.0 {
            return;
        }
        for a in &self.asteroids {
            if math::dist(self.ship.pos, a.pos) <= a.radius + 10.0 {
                if self.lives > 1 {
                    self.lives -= 1;
                    self.ship.pos = Vec2::new(self.width * 0.5, self.height * 0.5);
                    self.ship.vel = Vec2::ZERO;
                    self.invuln = 2.0;
                } else {
                    self.lives = 0;
                    self.phase = Phase::Over;
                }
                break;
            }
        }
    }

    fn spawn_wave(&mut self, count: usize) {
        let mut rng = rand::thread_rng();
        for _ in 0..count {
            let edge = rng.gen_range(0..4);
            let pos = match edge {
                0 => Vec2::new(rng.gen_range(0.0..self.width), 40.0),
                1 => Vec2::new(rng.gen_range(0.0..self.width), self.height - 40.0),
                2 => Vec2::new(40.0, rng.gen_range(0.0..self.height)),
                _ => Vec2::new(self.width - 40.0, rng.gen_range(0.0..self.height)),
            };
            self.asteroids.push(make_asteroid(pos, 0, &mut rng));
        }
    }
}

fn wrap(pos: &mut Vec2, w: f32, h: f32) {
    if pos.x < 0.0 {
        pos.x += w;
    }
    if pos.x > w {
        pos.x -= w;
    }
    if pos.y < 0.0 {
        pos.y += h;
    }
    if pos.y > h {
        pos.y -= h;
    }
}

fn make_asteroid(pos: Vec2, kind: u8, rng: &mut impl Rng) -> Asteroid {
    let radius = match kind {
        0 => 42.0,
        1 => 24.0,
        _ => 14.0,
    };
    let speed = match kind {
        0 => rng.gen_range(35.0..70.0),
        1 => rng.gen_range(55.0..100.0),
        _ => rng.gen_range(80.0..140.0),
    };
    let angle = rng.gen_range(0.0..std::f32::consts::TAU);
    Asteroid {
        pos,
        vel: math::from_angle(angle) * speed,
        radius,
        angle: rng.gen_range(0.0..std::f32::consts::TAU),
        spin: rng.gen_range(-1.5..1.5),
        sides: rng.gen_range(7..12),
        kind,
    }
}

fn split_asteroid(a: &Asteroid) -> Vec<Asteroid> {
    if a.kind >= 2 {
        return Vec::new();
    }
    let mut rng = rand::thread_rng();
    let next = a.kind + 1;
    vec![
        make_asteroid(a.pos, next, &mut rng),
        make_asteroid(a.pos, next, &mut rng),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn large_rocks_split_into_two_medium() {
        let rock = Asteroid {
            pos: Vec2::ZERO,
            vel: Vec2::ZERO,
            radius: 42.0,
            angle: 0.0,
            spin: 0.0,
            sides: 8,
            kind: 0,
        };
        let kids = split_asteroid(&rock);
        assert_eq!(kids.len(), 2);
        assert!(kids.iter().all(|k| k.kind == 1));
    }

    #[test]
    fn tiny_rocks_do_not_split() {
        let rock = Asteroid {
            pos: Vec2::ZERO,
            vel: Vec2::ZERO,
            radius: 14.0,
            angle: 0.0,
            spin: 0.0,
            sides: 8,
            kind: 2,
        };
        assert!(split_asteroid(&rock).is_empty());
    }
}
