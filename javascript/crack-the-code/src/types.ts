export type DigitLength = 3 | 4 | 5;
export type FeedbackMode = 'numeric' | 'color';
export type GameMode = 'one-player' | 'offline' | 'online';
export type Role = 'thinker' | 'guesser';
export type Outcome = 'won' | 'lost' | 'conflict';

export type Feedback = {
  plus: number;
  minus: number;
};

export type Guess = {
  value: string;
  plus: number;
  minus: number;
};

export const DIGIT_LENGTHS: DigitLength[] = [3, 4, 5];

export function guessLimitFor(length: DigitLength): number {
  if (length === 3) return 8;
  if (length === 4) return 10;
  return 12;
}

export type Session = {
  mode: GameMode;
  length: DigitLength;
  maxGuesses: number | null;
  localRole: Role;
  secret: string | null;
  guesses: Guess[];
  outcome: Outcome | null;
  computerGuess: string | null;
  thinkerName: string;
  guesserName: string;
};

export type ScreenName =
  | 'home'
  | 'onePlayerRole'
  | 'twoPlayerMode'
  | 'offlineSetup'
  | 'secretEntry'
  | 'playGuesser'
  | 'playThinker'
  | 'result'
  | 'onlineMenu'
  | 'createRoom'
  | 'joinRoom'
  | 'onlineSetup'
  | 'onlineSecret'
  | 'onlinePlay'
  | 'onlineResult';

export type OnlinePhase =
  | 'idle'
  | 'connecting'
  | 'waiting'
  | 'setup'
  | 'secret'
  | 'playing'
  | 'finished'
  | 'error';

export type OnlineState = {
  serverUrl: string;
  passcode: string | null;
  isHost: boolean;
  phase: OnlinePhase;
  error: string | null;
  playerCount: number;
};

export const DEFAULT_SERVER_URL = 'http://localhost:3457';
