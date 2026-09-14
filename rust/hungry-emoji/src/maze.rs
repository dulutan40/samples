//! Maze codes: `#` wall · `.` pellet · `o` power · ` ` empty · `-` gate · `P` player · `G` ghost
//! Every pellet tile is reachable from `P`. Layouts prefer loops over dead ends.

use std::collections::VecDeque;

pub const TILE: f32 = 24.0;
pub const LEVEL_COUNT: usize = 5;

pub const LEVELS: &[&[&str]] = &[
    // 1 — open training loops
    &[
        "###################",
        "#........#........#",
        "#o##.###.#.###.##o#",
        "#.................#",
        "#.###.#.###.#.###.#",
        "#.................#",
        "#.#####.#.#.#####.#",
        "#.....#.G.G.#.....#",
        "#.#.#.##---##.#.#.#",
        "#.#.#.........#.#.#",
        "#.#.###.#.#.###.#.#",
        "#.......#.#.......#",
        "###.#.#.....#.#.###",
        "#o.......P.......o#",
        "#.#####.#.#.#####.#",
        "#.................#",
        "###################",
    ],
    // 2 — twin rings
    &[
        "###################",
        "#o...............o#",
        "#.###.#######.###.#",
        "#.#.............#.#",
        "#.#.###...###.#.#.#",
        "#.#.............#.#",
        "#.#####.#.#.#####.#",
        "#.....#.G.G.#.....#",
        "#.#.#.##---##.#.#.#",
        "#.#.............#.#",
        "#.#.###.#.#.###.#.#",
        "#.......#.#.......#",
        "#.###.#.....#.###.#",
        "#o.......P.......o#",
        "#.#####.....#.###.#",
        "#.................#",
        "###################",
    ],
    // 3 — cross corridors
    &[
        "###################",
        "#........#........#",
        "#o##.#.#.#.#.#.##o#",
        "#....#.#...#.#....#",
        "###.##.##.##.##.###",
        "#.................#",
        "#.#####.#.#.#####.#",
        "#.....#.G.G.#.....#",
        "#.#.#.##---##.#.#.#",
        "#.#.#.........#.#.#",
        "#.#.###.#.#.###.#.#",
        "#.......#.#.......#",
        "###.###.....###.###",
        "#o.......P.......o#",
        "#.##.#########.##.#",
        "#.................#",
        "###################",
    ],
    // 4 — denser weave
    &[
        "###################",
        "#o....#.....#....o#",
        "#.###.#.###.#.###.#",
        "#.#...............#",
        "#.#.###.#.#.###.#.#",
        "#.................#",
        "#.#####.#.#.#####.#",
        "#.....#.G.G.#.....#",
        "#.#.#.##---##.#.#.#",
        "#.#.............#.#",
        "#.###.#.#.#.#.###.#",
        "#.....#.#.#.#.....#",
        "###.#.#.....#.#.###",
        "#o....#..P..#....o#",
        "#.#####.#.#.#####.#",
        "#.................#",
        "###################",
    ],
    // 5 — gauntlet
    &[
        "###################",
        "#........#........#",
        "#o##.#.#.#.#.#.##o#",
        "#....#.#...#.#....#",
        "###.##.#####.##.###",
        "#.................#",
        "#.#####.#.#.#####.#",
        "#.....#.G.G.#.....#",
        "#.#.#.##---##.#.#.#",
        "#.#.#.........#.#.#",
        "#.#.###.#.#.###.#.#",
        "#.....#.....#.....#",
        "#.#.#.#.....#.#.#.#",
        "#o..#....P....#..o#",
        "#.#####.#.#.#####.#",
        "#.................#",
        "###################",
    ],
];

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Cell {
    Wall,
    Empty,
    Pellet,
    Power,
    Gate,
}

pub struct Maze {
    pub cols: usize,
    pub rows: usize,
    pub cells: Vec<Cell>,
    pub player_start: (i32, i32),
    pub ghost_starts: Vec<(i32, i32)>,
    #[allow(dead_code)]
    pub level: usize,
}

impl Maze {
    pub fn parse_level(level: usize) -> Self {
        let idx = level.min(LEVEL_COUNT - 1);
        let raw = LEVELS[idx];
        let rows = raw.len();
        let cols = raw[0].len();
        let mut cells = vec![Cell::Wall; cols * rows];
        let mut player_start = (1, 1);
        let mut ghost_starts = Vec::new();

        for (y, line) in raw.iter().enumerate() {
            assert_eq!(line.len(), cols, "level {level} row {y} width mismatch");
            for (x, ch) in line.chars().enumerate() {
                let cell = match ch {
                    '#' => Cell::Wall,
                    '.' => Cell::Pellet,
                    'o' => Cell::Power,
                    '-' => Cell::Gate,
                    'P' => {
                        player_start = (x as i32, y as i32);
                        Cell::Empty
                    }
                    'G' => {
                        ghost_starts.push((x as i32, y as i32));
                        Cell::Empty
                    }
                    _ => Cell::Empty,
                };
                cells[y * cols + x] = cell;
            }
        }
        if ghost_starts.is_empty() {
            ghost_starts.push((cols as i32 / 2, rows as i32 / 2));
        }
        Self {
            cols,
            rows,
            cells,
            player_start,
            ghost_starts,
            level: idx,
        }
    }

    pub fn get(&self, x: i32, y: i32) -> Cell {
        if x < 0 || y < 0 || x >= self.cols as i32 || y >= self.rows as i32 {
            return Cell::Wall;
        }
        self.cells[y as usize * self.cols + x as usize]
    }

    pub fn set(&mut self, x: i32, y: i32, cell: Cell) {
        if x < 0 || y < 0 || x >= self.cols as i32 || y >= self.rows as i32 {
            return;
        }
        self.cells[y as usize * self.cols + x as usize] = cell;
    }

    pub fn walkable(&self, x: i32, y: i32, allow_gate: bool) -> bool {
        match self.get(x, y) {
            Cell::Wall => false,
            Cell::Gate => allow_gate,
            _ => true,
        }
    }

    pub fn pellet_count(&self) -> usize {
        self.cells
            .iter()
            .filter(|c| matches!(c, Cell::Pellet | Cell::Power))
            .count()
    }

    pub fn pixel_size(&self) -> (f32, f32) {
        (self.cols as f32 * TILE, self.rows as f32 * TILE)
    }

    /// Breadth-first: next step from `from` toward `to` (4-connected).
    pub fn next_step_toward(
        &self,
        from: (i32, i32),
        to: (i32, i32),
        allow_gate: bool,
    ) -> Option<(i32, i32)> {
        if from == to {
            return None;
        }
        let mut prev = vec![None; self.cols * self.rows];
        let mut q = VecDeque::new();
        let idx = |x: i32, y: i32| y as usize * self.cols + x as usize;
        q.push_back(to);
        prev[idx(to.0, to.1)] = Some(to);

        while let Some((x, y)) = q.pop_front() {
            for (dx, dy) in [(0, -1), (-1, 0), (0, 1), (1, 0)] {
                let nx = x + dx;
                let ny = y + dy;
                if !self.walkable(nx, ny, allow_gate) {
                    continue;
                }
                let i = idx(nx, ny);
                if prev[i].is_some() {
                    continue;
                }
                prev[i] = Some((x, y));
                if (nx, ny) == from {
                    return Some((x, y));
                }
                q.push_back((nx, ny));
            }
        }
        None
    }

    #[cfg(test)]
    pub fn reachable_from_player(&self) -> usize {
        let mut seen = vec![false; self.cols * self.rows];
        let mut q = VecDeque::new();
        let start = self.player_start;
        let idx = |x: i32, y: i32| y as usize * self.cols + x as usize;
        q.push_back(start);
        seen[idx(start.0, start.1)] = true;
        let mut pellets = 0;
        while let Some((x, y)) = q.pop_front() {
            match self.get(x, y) {
                Cell::Pellet | Cell::Power => pellets += 1,
                _ => {}
            }
            for (dx, dy) in [(0, -1), (-1, 0), (0, 1), (1, 0)] {
                let nx = x + dx;
                let ny = y + dy;
                if !self.walkable(nx, ny, false) {
                    continue;
                }
                let i = idx(nx, ny);
                if seen[i] {
                    continue;
                }
                seen[i] = true;
                q.push_back((nx, ny));
            }
        }
        pellets
    }

    /// Player-walkable cells that aren't loops (degree < 2), ignoring ghost house / gate.
    #[cfg(test)]
    pub fn dead_end_count(&self) -> usize {
        let mut count = 0;
        for y in 0..self.rows as i32 {
            for x in 0..self.cols as i32 {
                match self.get(x, y) {
                    Cell::Wall | Cell::Gate => continue,
                    _ => {}
                }
                if !self.walkable(x, y, false) {
                    continue;
                }
                let degree = [(0, -1), (-1, 0), (0, 1), (1, 0)]
                    .iter()
                    .filter(|(dx, dy)| self.walkable(x + dx, y + dy, false))
                    .count();
                if degree < 2 {
                    count += 1;
                }
            }
        }
        count
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_level_is_fully_reachable() {
        for level in 0..LEVEL_COUNT {
            let m = Maze::parse_level(level);
            assert_eq!(
                m.reachable_from_player(),
                m.pellet_count(),
                "level {level}: unreachable pellets"
            );
            assert_eq!(m.dead_end_count(), 0, "level {level}: dead ends");
            assert!(m.pellet_count() > 30, "level {level} too empty");
            assert!(m.ghost_starts.len() >= 2);
        }
    }
}
