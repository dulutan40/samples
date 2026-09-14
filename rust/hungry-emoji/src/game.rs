use crate::maze::{Cell, Maze, TILE};

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Dir {
    Up,
    Down,
    Left,
    Right,
}

impl Dir {
    pub fn delta(self) -> (i32, i32) {
        match self {
            Dir::Up => (0, -1),
            Dir::Down => (0, 1),
            Dir::Left => (-1, 0),
            Dir::Right => (1, 0),
        }
    }

    pub fn opposite(self) -> Dir {
        match self {
            Dir::Up => Dir::Down,
            Dir::Down => Dir::Up,
            Dir::Left => Dir::Right,
            Dir::Right => Dir::Left,
        }
    }

    pub fn angle(self) -> f32 {
        match self {
            Dir::Right => 0.0,
            Dir::Down => std::f32::consts::FRAC_PI_2,
            Dir::Left => std::f32::consts::PI,
            Dir::Up => -std::f32::consts::FRAC_PI_2,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Phase {
    Ready,
    Playing,
    Won,
    Lost,
}

#[derive(Clone, Copy)]
pub struct Actor {
    pub tx: i32,
    pub ty: i32,
    pub x: f32,
    pub y: f32,
    pub dir: Dir,
    pub next: Option<Dir>,
}

impl Actor {
    fn at(tile: (i32, i32), dir: Dir) -> Self {
        Self {
            tx: tile.0,
            ty: tile.1,
            x: tile.0 as f32 * TILE + TILE * 0.5,
            y: tile.1 as f32 * TILE + TILE * 0.5,
            dir,
            next: None,
        }
    }

    fn center_tile(&self) -> bool {
        let cx = self.tx as f32 * TILE + TILE * 0.5;
        let cy = self.ty as f32 * TILE + TILE * 0.5;
        (self.x - cx).abs() < 1.2 && (self.y - cy).abs() < 1.2
    }

    fn snap(&mut self) {
        self.x = self.tx as f32 * TILE + TILE * 0.5;
        self.y = self.ty as f32 * TILE + TILE * 0.5;
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum GhostMode {
    Chase,
    Frightened,
    Eaten,
}

pub struct Ghost {
    pub actor: Actor,
    pub color: [u8; 3],
    pub mode: GhostMode,
    pub home: (i32, i32),
}

pub struct Game {
    pub maze: Maze,
    pub player: Actor,
    pub ghosts: Vec<Ghost>,
    pub score: u32,
    pub lives: u32,
    pub phase: Phase,
    pub frightened: f32,
    pub chomp: f32,
    speed: f32,
}

impl Game {
    pub fn new() -> Self {
        let maze = Maze::parse();
        let player = Actor::at(maze.player_start, Dir::Left);
        let palette = [
            [255, 80, 80],
            [255, 160, 200],
            [80, 220, 255],
            [255, 160, 60],
        ];
        let ghosts = maze
            .ghost_starts
            .iter()
            .enumerate()
            .map(|(i, &home)| Ghost {
                actor: Actor::at(home, Dir::Up),
                color: palette[i % palette.len()],
                mode: GhostMode::Chase,
                home,
            })
            .collect();
        Self {
            maze,
            player,
            ghosts,
            score: 0,
            lives: 3,
            phase: Phase::Ready,
            frightened: 0.0,
            chomp: 0.0,
            speed: 110.0,
        }
    }

    pub fn queue_dir(&mut self, dir: Dir) {
        self.player.next = Some(dir);
    }

    pub fn update(&mut self, dt: f32) {
        if self.phase != Phase::Playing {
            return;
        }
        self.chomp += dt * 10.0;
        if self.frightened > 0.0 {
            self.frightened = (self.frightened - dt).max(0.0);
            if self.frightened == 0.0 {
                for g in &mut self.ghosts {
                    if g.mode == GhostMode::Frightened {
                        g.mode = GhostMode::Chase;
                    }
                }
            }
        }

        Self::step_actor(&self.maze, &mut self.player, self.speed, dt, false);
        self.eat_tile();

        let ghost_speed = if self.frightened > 0.0 {
            self.speed * 0.7
        } else {
            self.speed * 0.95
        };
        let player_tile = (self.player.tx, self.player.ty);
        for i in 0..self.ghosts.len() {
            self.steer_ghost(i, player_tile);
            let allow_gate = self.ghosts[i].mode == GhostMode::Eaten;
            let speed = if self.ghosts[i].mode == GhostMode::Eaten {
                self.speed * 1.4
            } else {
                ghost_speed
            };
            Self::step_actor(&self.maze, &mut self.ghosts[i].actor, speed, dt, allow_gate);
            if self.ghosts[i].mode == GhostMode::Eaten
                && self.ghosts[i].actor.tx == self.ghosts[i].home.0
                && self.ghosts[i].actor.ty == self.ghosts[i].home.1
            {
                self.ghosts[i].mode = GhostMode::Chase;
            }
        }

        self.resolve_touches();
        if self.maze.pellet_count() == 0 {
            self.phase = Phase::Won;
        }
    }

    fn eat_tile(&mut self) {
        let (x, y) = (self.player.tx, self.player.ty);
        match self.maze.get(x, y) {
            Cell::Pellet => {
                self.maze.set(x, y, Cell::Empty);
                self.score += 10;
            }
            Cell::Power => {
                self.maze.set(x, y, Cell::Empty);
                self.score += 50;
                self.frightened = 6.0;
                for g in &mut self.ghosts {
                    if g.mode != GhostMode::Eaten {
                        g.mode = GhostMode::Frightened;
                        g.actor.dir = g.actor.dir.opposite();
                        g.actor.next = None;
                    }
                }
            }
            _ => {}
        }
    }

    fn step_actor(maze: &Maze, actor: &mut Actor, speed: f32, dt: f32, allow_gate: bool) {
        if actor.center_tile() {
            actor.snap();
            if let Some(next) = actor.next {
                let (dx, dy) = next.delta();
                if maze.walkable(actor.tx + dx, actor.ty + dy, allow_gate) {
                    actor.dir = next;
                    actor.next = None;
                }
            }
            let (dx, dy) = actor.dir.delta();
            if !maze.walkable(actor.tx + dx, actor.ty + dy, allow_gate) {
                return;
            }
            actor.tx += dx;
            actor.ty += dy;
        }

        let (dx, dy) = actor.dir.delta();
        actor.x += dx as f32 * speed * dt;
        actor.y += dy as f32 * speed * dt;

        let max_x = (maze.cols as f32) * TILE;
        if actor.x < 0.0 {
            actor.x += max_x;
            actor.tx = maze.cols as i32 - 1;
        } else if actor.x >= max_x {
            actor.x -= max_x;
            actor.tx = 0;
        }
    }

    fn steer_ghost(&mut self, index: usize, target: (i32, i32)) {
        let ghost = &self.ghosts[index];
        if !ghost.actor.center_tile() {
            return;
        }
        let mode = ghost.mode;
        let (tx, ty) = (ghost.actor.tx, ghost.actor.ty);
        let cur = ghost.actor.dir;
        let home = ghost.home;
        let allow_gate = mode == GhostMode::Eaten;

        let goal = match mode {
            GhostMode::Chase => target,
            GhostMode::Frightened => home,
            GhostMode::Eaten => home,
        };

        let mut options = [Dir::Up, Dir::Left, Dir::Down, Dir::Right];
        // deterministic shuffle by tile
        let seed = (tx * 13 + ty * 7 + index as i32 * 3).rem_euclid(4) as usize;
        options.rotate_left(seed);

        let mut best = cur;
        let mut best_score = i32::MIN;
        for dir in options {
            if dir == cur.opposite() && mode != GhostMode::Eaten {
                continue;
            }
            let (dx, dy) = dir.delta();
            let nx = tx + dx;
            let ny = ty + dy;
            if !self.maze.walkable(nx, ny, allow_gate) {
                continue;
            }
            let dist = (nx - goal.0).pow(2) + (ny - goal.1).pow(2);
            let score = if mode == GhostMode::Frightened {
                dist
            } else {
                -dist
            };
            if score > best_score {
                best_score = score;
                best = dir;
            }
        }
        self.ghosts[index].actor.next = Some(best);
    }

    fn resolve_touches(&mut self) {
        for g in &mut self.ghosts {
            let dx = g.actor.x - self.player.x;
            let dy = g.actor.y - self.player.y;
            if dx * dx + dy * dy > (TILE * 0.55).powi(2) {
                continue;
            }
            match g.mode {
                GhostMode::Frightened => {
                    g.mode = GhostMode::Eaten;
                    self.score += 200;
                }
                GhostMode::Chase => {
                    if self.lives > 1 {
                        self.lives -= 1;
                        self.reset_actors();
                    } else {
                        self.lives = 0;
                        self.phase = Phase::Lost;
                    }
                    return;
                }
                GhostMode::Eaten => {}
            }
        }
    }

    fn reset_actors(&mut self) {
        self.player = Actor::at(self.maze.player_start, Dir::Left);
        for g in &mut self.ghosts {
            g.actor = Actor::at(g.home, Dir::Up);
            g.mode = GhostMode::Chase;
        }
        self.frightened = 0.0;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn eating_pellet_scores() {
        let mut game = Game::new();
        game.phase = Phase::Playing;
        let before = game.maze.pellet_count();
        // force eat at player tile if empty, place pellet
        game.maze.set(game.player.tx, game.player.ty, Cell::Pellet);
        game.eat_tile();
        assert_eq!(game.score, 10);
        assert!(game.maze.pellet_count() < before || before == game.maze.pellet_count());
    }
}
