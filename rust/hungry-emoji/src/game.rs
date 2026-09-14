use crate::maze::{Cell, Maze, LEVEL_COUNT, TILE};

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

    pub fn from_delta(dx: i32, dy: i32) -> Option<Dir> {
        match (dx, dy) {
            (0, -1) => Some(Dir::Up),
            (0, 1) => Some(Dir::Down),
            (-1, 0) => Some(Dir::Left),
            (1, 0) => Some(Dir::Right),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Phase {
    Ready,
    Playing,
    LevelClear,
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
        (self.x - cx).abs() < 1.5 && (self.y - cy).abs() < 1.5
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
    pub level: usize,
    pub phase: Phase,
    pub frightened: f32,
    pub chomp: f32,
    speed: f32,
}

impl Game {
    pub fn new() -> Self {
        Self::for_level(0, 0, 3)
    }

    pub fn for_level(level: usize, score: u32, lives: u32) -> Self {
        let level = level.min(LEVEL_COUNT - 1);
        let maze = Maze::parse_level(level);
        let player = Actor::at(maze.player_start, Dir::Left);
        let palette = [
            [255, 80, 80],
            [255, 160, 200],
            [80, 220, 255],
            [255, 160, 60],
        ];
        let ghost_count = (2 + level).min(maze.ghost_starts.len()).max(1);
        let ghosts = maze
            .ghost_starts
            .iter()
            .take(ghost_count)
            .enumerate()
            .map(|(i, &home)| Ghost {
                actor: Actor::at(home, Dir::Up),
                color: palette[i % palette.len()],
                mode: GhostMode::Chase,
                home,
            })
            .collect();
        let speed = 100.0 + level as f32 * 12.0;
        Self {
            maze,
            player,
            ghosts,
            score,
            lives,
            level,
            phase: Phase::Ready,
            frightened: 0.0,
            chomp: 0.0,
            speed,
        }
    }

    pub fn begin(&mut self) {
        self.phase = Phase::Playing;
    }

    pub fn advance_after_clear(&mut self) {
        if self.phase != Phase::LevelClear {
            return;
        }
        let next = self.level + 1;
        if next >= LEVEL_COUNT {
            self.phase = Phase::Won;
            return;
        }
        let score = self.score;
        let lives = self.lives;
        *self = Self::for_level(next, score, lives);
        self.phase = Phase::Playing;
    }

    pub fn retry(&mut self) {
        *self = Self::new();
        self.phase = Phase::Playing;
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

        let player_tile = (self.player.tx, self.player.ty);
        for i in 0..self.ghosts.len() {
            self.steer_ghost(i, player_tile);
            // Ghosts may use the house gate (player cannot) so eaten eyes can
            // return home and respawned ghosts can leave again.
            let speed = match self.ghosts[i].mode {
                GhostMode::Eaten => self.speed * 1.6,
                GhostMode::Frightened => self.speed * 0.65,
                GhostMode::Chase => self.speed * (0.9 + self.level as f32 * 0.04),
            };
            Self::step_actor(&self.maze, &mut self.ghosts[i].actor, speed, dt, true);

            if self.ghosts[i].mode == GhostMode::Eaten {
                let home = self.ghosts[i].home;
                let a = &self.ghosts[i].actor;
                if a.tx == home.0 && a.ty == home.1 && a.center_tile() {
                    self.ghosts[i].mode = GhostMode::Chase;
                    self.ghosts[i].actor.snap();
                    self.ghosts[i].actor.dir = Dir::Up;
                    self.ghosts[i].actor.next = Some(Dir::Up);
                }
            }
        }

        self.resolve_touches();
        if self.maze.pellet_count() == 0 {
            if self.level + 1 >= LEVEL_COUNT {
                self.phase = Phase::Won;
            } else {
                self.phase = Phase::LevelClear;
            }
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
                self.frightened = (6.0 - self.level as f32 * 0.4).max(3.5);
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
                // Idle at center if blocked (wait for a valid next).
                return;
            }
            actor.tx += dx;
            actor.ty += dy;
        }

        let (dx, dy) = actor.dir.delta();
        actor.x += dx as f32 * speed * dt;
        actor.y += dy as f32 * speed * dt;
    }

    fn steer_ghost(&mut self, index: usize, player: (i32, i32)) {
        let ghost = &self.ghosts[index];
        if !ghost.actor.center_tile() {
            return;
        }
        let mode = ghost.mode;
        let from = (ghost.actor.tx, ghost.actor.ty);
        let home = ghost.home;
        let cur = ghost.actor.dir;

        let chosen = match mode {
            GhostMode::Eaten => {
                if let Some(next_cell) = self.maze.next_step_toward(from, home, true) {
                    Dir::from_delta(next_cell.0 - from.0, next_cell.1 - from.1)
                } else {
                    None
                }
            }
            GhostMode::Frightened => Self::pick_flee(&self.maze, from, player, cur, true),
            GhostMode::Chase => {
                if let Some(next_cell) = self.maze.next_step_toward(from, player, true) {
                    Dir::from_delta(next_cell.0 - from.0, next_cell.1 - from.1)
                } else {
                    Self::pick_any(&self.maze, from, cur, true)
                }
            }
        };

        if let Some(dir) = chosen {
            self.ghosts[index].actor.next = Some(dir);
        } else if let Some(dir) = Self::pick_any(&self.maze, from, cur, true) {
            self.ghosts[index].actor.next = Some(dir);
        }
    }

    fn pick_flee(
        maze: &Maze,
        from: (i32, i32),
        threat: (i32, i32),
        cur: Dir,
        allow_gate: bool,
    ) -> Option<Dir> {
        let mut best = None;
        let mut best_dist = -1;
        for dir in [Dir::Up, Dir::Left, Dir::Down, Dir::Right] {
            if dir == cur.opposite() {
                continue;
            }
            let (dx, dy) = dir.delta();
            let nx = from.0 + dx;
            let ny = from.1 + dy;
            if !maze.walkable(nx, ny, allow_gate) {
                continue;
            }
            let dist = (nx - threat.0).pow(2) + (ny - threat.1).pow(2);
            if dist > best_dist {
                best_dist = dist;
                best = Some(dir);
            }
        }
        best.or_else(|| Self::pick_any(maze, from, cur, allow_gate))
    }

    fn pick_any(maze: &Maze, from: (i32, i32), cur: Dir, allow_gate: bool) -> Option<Dir> {
        for dir in [cur, Dir::Up, Dir::Left, Dir::Down, Dir::Right, cur.opposite()] {
            let (dx, dy) = dir.delta();
            if maze.walkable(from.0 + dx, from.1 + dy, allow_gate) {
                return Some(dir);
            }
        }
        None
    }

    fn resolve_touches(&mut self) {
        for i in 0..self.ghosts.len() {
            let dx = self.ghosts[i].actor.x - self.player.x;
            let dy = self.ghosts[i].actor.y - self.player.y;
            if dx * dx + dy * dy > (TILE * 0.55).powi(2) {
                continue;
            }
            match self.ghosts[i].mode {
                GhostMode::Frightened => {
                    let from = (
                        self.ghosts[i].actor.tx,
                        self.ghosts[i].actor.ty,
                    );
                    let home = self.ghosts[i].home;
                    self.ghosts[i].mode = GhostMode::Eaten;
                    self.ghosts[i].actor.next = None;
                    if let Some(next_cell) = self.maze.next_step_toward(from, home, true) {
                        if let Some(dir) =
                            Dir::from_delta(next_cell.0 - from.0, next_cell.1 - from.1)
                        {
                            self.ghosts[i].actor.dir = dir;
                            self.ghosts[i].actor.next = Some(dir);
                        }
                    }
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
        game.maze.set(game.player.tx, game.player.ty, Cell::Pellet);
        game.eat_tile();
        assert_eq!(game.score, 10);
    }

    #[test]
    fn clearing_level_advances() {
        let mut game = Game::for_level(0, 0, 3);
        game.phase = Phase::LevelClear;
        game.advance_after_clear();
        assert_eq!(game.level, 1);
        assert_eq!(game.phase, Phase::Playing);
    }

    #[test]
    fn eaten_ghost_can_path_home_through_gate() {
        let game = Game::for_level(0, 0, 3);
        let home = game.ghosts[0].home;
        // Just below the gate band (gate is on the row under the ghosts).
        let from = (home.0, home.1 + 2);
        assert!(
            game.maze.walkable(from.0, from.1, false),
            "expected open tile below house"
        );
        assert!(
            game.maze.next_step_toward(from, home, true).is_some(),
            "eaten ghost must path home via gate"
        );
        assert!(
            game.maze.next_step_toward(home, from, true).is_some(),
            "respawned ghost must leave house via gate"
        );
    }
}
