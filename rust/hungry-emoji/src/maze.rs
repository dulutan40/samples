//! Compact maze: `#` wall, `.` pellet, `o` power, ` ` empty, `-` ghost gate, `P` start, `G` ghost.

pub const TILE: f32 = 24.0;

pub const RAW: &[&str] = &[
    "###################",
    "#........#........#",
    "#o##.###.#.###.##o#",
    "#.................#",
    "#.##.#.#####.#.##.#",
    "#....#...#...#....#",
    "####.### # ###.####",
    "   #.#   G   #.#   ",
    "####.# ##-## #.####",
    "#........#........#",
    "#.##.###.#.###.##.#",
    "#o..#....P....#..o#",
    "###.#.#.#####.#.###",
    "#.....#...#...#...#",
    "#.#######.#.#######",
    "#.................#",
    "###################",
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
}

impl Maze {
    pub fn parse() -> Self {
        let rows = RAW.len();
        let cols = RAW[0].len();
        let mut cells = vec![Cell::Wall; cols * rows];
        let mut player_start = (1, 1);
        let mut ghost_starts = Vec::new();

        for (y, line) in RAW.iter().enumerate() {
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
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maze_has_start_and_pellets() {
        let m = Maze::parse();
        assert!(m.pellet_count() > 20);
        assert_ne!(m.get(m.player_start.0, m.player_start.1), Cell::Wall);
    }
}
