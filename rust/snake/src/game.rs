use rand::Rng;
use std::collections::VecDeque;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Dir {
    Up,
    Down,
    Left,
    Right,
}

impl Dir {
    fn delta(self) -> (i32, i32) {
        match self {
            Dir::Up => (0, -1),
            Dir::Down => (0, 1),
            Dir::Left => (-1, 0),
            Dir::Right => (1, 0),
        }
    }

    fn opposite(self) -> Dir {
        match self {
            Dir::Up => Dir::Down,
            Dir::Down => Dir::Up,
            Dir::Left => Dir::Right,
            Dir::Right => Dir::Left,
        }
    }
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Cell {
    pub x: i32,
    pub y: i32,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Phase {
    Ready,
    Playing,
    Over,
}

pub struct Game {
    pub cols: i32,
    pub rows: i32,
    pub snake: VecDeque<Cell>,
    pub dir: Dir,
    pub food: Cell,
    pub score: u32,
    pub phase: Phase,
    grow: u32,
}

impl Game {
    pub fn new(cols: i32, rows: i32) -> Self {
        let mut snake = VecDeque::new();
        let cx = cols / 2;
        let cy = rows / 2;
        snake.push_back(Cell { x: cx, y: cy });
        snake.push_back(Cell { x: cx - 1, y: cy });
        snake.push_back(Cell { x: cx - 2, y: cy });

        let mut game = Self {
            cols,
            rows,
            snake,
            dir: Dir::Right,
            food: Cell { x: 0, y: 0 },
            score: 0,
            phase: Phase::Ready,
            grow: 0,
        };
        game.place_food();
        game
    }

    pub fn try_turn(&mut self, next: Dir) {
        if next != self.dir.opposite() {
            self.dir = next;
        }
    }

    pub fn step(&mut self) {
        if self.phase != Phase::Playing {
            return;
        }

        let head = self.snake.front().copied().unwrap();
        let (dx, dy) = self.dir.delta();
        let next = Cell {
            x: head.x + dx,
            y: head.y + dy,
        };

        if next.x < 0 || next.y < 0 || next.x >= self.cols || next.y >= self.rows {
            self.phase = Phase::Over;
            return;
        }
        if self.snake.iter().any(|c| *c == next) {
            self.phase = Phase::Over;
            return;
        }

        self.snake.push_front(next);
        if next == self.food {
            self.score += 1;
            self.grow += 2;
            self.place_food();
        }

        if self.grow > 0 {
            self.grow -= 1;
        } else {
            self.snake.pop_back();
        }
    }

    fn place_food(&mut self) {
        let mut rng = rand::thread_rng();
        loop {
            let cell = Cell {
                x: rng.gen_range(0..self.cols),
                y: rng.gen_range(0..self.rows),
            };
            if !self.snake.iter().any(|c| *c == cell) {
                self.food = cell;
                break;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn turning_into_yourself_is_ignored() {
        let mut game = Game::new(10, 10);
        game.phase = Phase::Playing;
        game.dir = Dir::Right;
        game.try_turn(Dir::Left);
        assert_eq!(game.dir, Dir::Right);
    }

    #[test]
    fn eating_grows_the_snake() {
        let mut game = Game::new(10, 10);
        game.phase = Phase::Playing;
        let start_len = game.snake.len();
        let head = *game.snake.front().unwrap();
        game.food = Cell {
            x: head.x + 1,
            y: head.y,
        };
        game.dir = Dir::Right;
        game.step();
        assert!(game.snake.len() > start_len);
        assert_eq!(game.score, 1);
    }
}
