import type { DigitLength, Feedback, Guess } from '../types';

const codeCache = new Map<number, string[]>();

export function evaluateGuess(secret: string, guess: string): Feedback {
  let plus = 0;
  const secretRest: string[] = [];
  const guessRest: string[] = [];

  for (let i = 0; i < secret.length; i += 1) {
    if (secret[i] === guess[i]) {
      plus += 1;
    } else {
      secretRest.push(secret[i]);
      guessRest.push(guess[i]);
    }
  }

  let minus = 0;
  for (const digit of guessRest) {
    const index = secretRest.indexOf(digit);
    if (index !== -1) {
      minus += 1;
      secretRest.splice(index, 1);
    }
  }

  return { plus, minus };
}

export function isValidCode(code: string, length: number): boolean {
  return code.length === length && /^\d+$/.test(code) && new Set(code).size === length;
}

export function isWon(feedback: Feedback, length: number): boolean {
  return feedback.plus === length;
}

export function missCount(feedback: Feedback, length: number): number {
  return length - feedback.plus - feedback.minus;
}

export function formatNumeric(feedback: Feedback): string {
  return `+${feedback.plus}  −${feedback.minus}`;
}

export function remainingGuesses(maxGuesses: number | null, used: number): number | null {
  if (maxGuesses == null) return null;
  return Math.max(0, maxGuesses - used);
}

export function pickSecret(length: DigitLength): string {
  const digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  for (let i = digits.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    const swap = digits[i];
    digits[i] = digits[j];
    digits[j] = swap;
  }
  return digits.slice(0, length).join('');
}

export function allCodes(length: DigitLength): string[] {
  const cached = codeCache.get(length);
  if (cached) return cached;

  const codes: string[] = [];
  const used = Array.from({ length: 10 }, () => false);

  const walk = (prefix: string) => {
    if (prefix.length === length) {
      codes.push(prefix);
      return;
    }
    for (let digit = 0; digit <= 9; digit += 1) {
      if (used[digit]) continue;
      used[digit] = true;
      walk(prefix + String(digit));
      used[digit] = false;
    }
  };

  walk('');
  codeCache.set(length, codes);
  return codes;
}

function sameFeedback(left: Feedback, right: Feedback): boolean {
  return left.plus === right.plus && left.minus === right.minus;
}

export function nextComputerGuess(length: DigitLength, history: Guess[]): string | null {
  if (history.length === 0) {
    return '0123456789'.slice(0, length);
  }

  const remaining = allCodes(length).filter((code) =>
    history.every((guess) => sameFeedback(evaluateGuess(code, guess.value), guess)),
  );

  if (remaining.length === 0) return null;
  return remaining[Math.floor(Math.random() * remaining.length)];
}

export function isFeedbackPossible(length: number, plus: number, minus: number): boolean {
  return (
    Number.isInteger(plus) &&
    Number.isInteger(minus) &&
    plus >= 0 &&
    minus >= 0 &&
    plus + minus <= length
  );
}
