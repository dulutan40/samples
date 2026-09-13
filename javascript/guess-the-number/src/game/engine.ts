import type { Guess, GuessResult } from '../types';

export function pickSecret(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export function evaluateGuess(guess: number, secret: number): GuessResult {
  if (guess === secret) return 'correct';
  return guess < secret ? 'lower' : 'higher';
}

export function isInRange(value: number, min: number, max: number): boolean {
  return Number.isInteger(value) && value >= min && value <= max;
}

export function remainingGuesses(maxGuesses: number | null, used: number): number | null {
  if (maxGuesses == null) return null;
  return Math.max(0, maxGuesses - used);
}

export function boundsFromFeedback(
  min: number,
  max: number,
  guesses: Guess[],
): { low: number; high: number; valid: boolean } {
  let low = min;
  let high = max;

  for (const guess of guesses) {
    if (guess.result === 'lower') {
      low = Math.max(low, guess.value + 1);
    } else if (guess.result === 'higher') {
      high = Math.min(high, guess.value - 1);
    }
  }

  return { low, high, valid: low <= high };
}

export function nextComputerGuess(min: number, max: number, guesses: Guess[]): number | null {
  const { low, high, valid } = boundsFromFeedback(min, max, guesses);
  if (!valid) return null;
  return Math.floor((low + high) / 2);
}

export function resultCopy(result: GuessResult): { title: string; detail: string } {
  if (result === 'correct') {
    return { title: 'Correct', detail: 'That is the number.' };
  }
  if (result === 'lower') {
    return { title: 'Too low', detail: 'The number is higher than this guess.' };
  }
  return { title: 'Too high', detail: 'The number is lower than this guess.' };
}
