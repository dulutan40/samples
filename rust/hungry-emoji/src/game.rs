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
                actor: Actor::at(home, Dir::Down),
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
        // Cap dt so a hitch can't fling actors past tile centers.
        let dt = dt.clamp(0.0, 1.0 / 20.0);
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
                    self.ghosts[i].actor.dir = Dir::Down;
                    self.ghosts[i].actor.next = Some(Dir::Down);
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
        // `tx/ty` is the tile whose center we are moving toward. On arrival we
        // choose a direction and commit to the next tile. Movement is clamped
        // so large `dt` / speed cannot skip the center and fly off-map.
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
        let target_x = actor.tx as f32 * TILE + TILE * 0.5;
        let target_y = actor.ty as f32 * TILE + TILE * 0.5;
        let remaining = if dx != 0 {
            (target_x - actor.x) * dx as f32
        } else if dy != 0 {
            (target_y - actor.y) * dy as f32
        } else {
            0.0
        };

        if remaining <= 0.0 {
            actor.snap();
            return;
        }

        let step = (speed * dt).min(remaining);
        actor.x += dx as f32 * step;
        actor.y += dy as f32 * step;
        if step >= remaining - 0.001 {
            actor.snap();
        }
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
            GhostMode::Chase => self.pick_chase(index, from, player, cur),
        };

        if let Some(dir) = chosen {
            self.ghosts[index].actor.next = Some(dir);
        } else if let Some(dir) = Self::pick_any(&self.maze, from, cur, true) {
            self.ghosts[index].actor.next = Some(dir);
        }
    }

    /// Each ghost aims at a slightly different point so they don't all BFS the same lane.
    fn chase_target(&self, index: usize, player: (i32, i32)) -> (i32, i32) {
        let (dx, dy) = self.player.dir.delta();
        let cols = self.maze.cols as i32;
        let rows = self.maze.rows as i32;
        let clamp = |x: i32, y: i32| (x.clamp(1, cols - 2), y.clamp(1, rows - 2));
        match index % 4 {
            0 => player,
            1 => clamp(player.0 + dx * 4, player.1 + dy * 4),
            2 => {
                let (px, py) = (-dy, dx);
                clamp(player.0 + dx * 2 + px * 2, player.1 + dy * 2 + py * 2)
            }
            _ => {
                let g = &self.ghosts[index];
                let dist =
                    (g.actor.tx - player.0).pow(2) + (g.actor.ty - player.1).pow(2);
                if dist < 64 {
                    let corners = [
                        (1, 1),
                        (cols - 2, 1),
                        (1, rows - 2),
                        (cols - 2, rows - 2),
                    ];
                    corners[index % corners.len()]
                } else {
                    player
                }
            }
        }
    }

    fn pick_chase(
        &self,
        index: usize,
        from: (i32, i32),
        player: (i32, i32),
        cur: Dir,
    ) -> Option<Dir> {
        let target = self.chase_target(index, player);
        let primary = self
            .maze
            .next_step_toward(from, target, true)
            .and_then(|next_cell| Dir::from_delta(next_cell.0 - from.0, next_cell.1 - from.1))
            .or_else(|| Self::pick_any(&self.maze, from, cur, true))?;

        let (dx, dy) = primary.delta();
        let next = (from.0 + dx, from.1 + dy);
        if self.chase_path_conflict(index, from, next, primary) {
            Self::pick_breakaway(&self.maze, from, cur, primary, true).or(Some(primary))
        } else {
            Some(primary)
        }
    }

    /// True when another chasing ghost already owns this lane / next tile.
    fn chase_path_conflict(
        &self,
        index: usize,
        from: (i32, i32),
        next: (i32, i32),
        dir: Dir,
    ) -> bool {
        for (j, other) in self.ghosts.iter().enumerate() {
            if j == index || other.mode != GhostMode::Chase {
                continue;
            }
            let ot = (other.actor.tx, other.actor.ty);
            // Same tile: lower index keeps the primary path.
            if ot == from {
                return j < index;
            }
            // Someone is already sitting on the step we want.
            if ot == next {
                return true;
            }
            // Someone ahead is heading into the same cell on the same heading.
            let other_next = other.actor.next.unwrap_or(other.actor.dir);
            let (ox, oy) = other_next.delta();
            if (other.actor.tx + ox, other.actor.ty + oy) == next && other_next == dir {
                return true;
            }
        }
        false
    }

    fn pick_breakaway(
        maze: &Maze,
        from: (i32, i32),
        cur: Dir,
        avoid: Dir,
        allow_gate: bool,
    ) -> Option<Dir> {
        // Prefer a side route over reversing or staying glued to `avoid`.
        for dir in [Dir::Up, Dir::Left, Dir::Down, Dir::Right] {
            if dir == avoid || dir == cur.opposite() {
                continue;
            }
            let (dx, dy) = dir.delta();
            if maze.walkable(from.0 + dx, from.1 + dy, allow_gate) {
                return Some(dir);
            }
        }
        for dir in [Dir::Up, Dir::Left, Dir::Down, Dir::Right] {
            if dir == avoid {
                continue;
            }
            let (dx, dy) = dir.delta();
            if maze.walkable(from.0 + dx, from.1 + dy, allow_gate) {
                return Some(dir);
            }
        }
        None
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
            g.actor = Actor::at(g.home, Dir::Down);
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

    #[test]
    fn ghosts_stay_on_maze_even_with_large_dt() {
        let mut game = Game::for_level(0, 0, 3);
        game.phase = Phase::Playing;
        let (w, h) = game.maze.pixel_size();
        for _ in 0..600 {
            game.update(1.0 / 20.0); // capped path, still stressful
            for g in &game.ghosts {
                assert!(
                    g.actor.x >= -TILE && g.actor.x <= w + TILE,
                    "ghost x {} out of bounds",
                    g.actor.x
                );
                assert!(
                    g.actor.y >= -TILE && g.actor.y <= h + TILE,
                    "ghost y {} out of bounds",
                    g.actor.y
                );
                assert!(
                    game.maze
                        .walkable(g.actor.tx, g.actor.ty, true),
                    "ghost tile ({},{}) not walkable",
                    g.actor.tx,
                    g.actor.ty
                );
            }
        }
    }

    #[test]
    fn eaten_ghost_returns_home_and_leaves() {
        let mut game = Game::for_level(0, 0, 3);
        game.phase = Phase::Playing;
        let home = game.ghosts[0].home;
        // Place ghost in the open maze below the house and mark eaten.
        let start = (home.0, home.1 + 2);
        game.ghosts[0].actor = Actor::at(start, Dir::Up);
        game.ghosts[0].mode = GhostMode::Eaten;
        let mut returned = false;
        let mut left_house = false;
        for _ in 0..400 {
            game.update(1.0 / 30.0);
            let g = &game.ghosts[0];
            if g.mode == GhostMode::Eaten && g.actor.tx == home.0 && g.actor.ty == home.1 {
                returned = true;
            }
            if returned && g.mode == GhostMode::Chase {
                if g.actor.ty > home.1 {
                    left_house = true;
                    break;
                }
            }
        }
        assert!(returned, "eaten ghost never reached home");
        assert!(left_house, "ghost never left the house after respawn");
    }

    #[test]
    fn stacked_chasers_break_apart() {
        let mut game = Game::for_level(0, 0, 3);
        game.phase = Phase::Playing;
        let tile = (3, 5);
        assert!(game.maze.walkable(tile.0, tile.1, false));
        game.player = Actor::at((15, 5), Dir::Left);
        game.ghosts[0].actor = Actor::at(tile, Dir::Right);
        game.ghosts[0].mode = GhostMode::Chase;
        game.ghosts[1].actor = Actor::at(tile, Dir::Right);
        game.ghosts[1].mode = GhostMode::Chase;

        game.steer_ghost(0, (game.player.tx, game.player.ty));
        game.steer_ghost(1, (game.player.tx, game.player.ty));

        let d0 = game.ghosts[0].actor.next.expect("ghost 0 should steer");
        let d1 = game.ghosts[1].actor.next.expect("ghost 1 should steer");
        assert_ne!(
            d0, d1,
            "stacked ghosts should not commit to the same next step ({d0:?})"
        );
    }
}
