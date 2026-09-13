export type GuessResult = 'correct' | 'lower' | 'higher';

export type Guess = {
  value: number;
  result: GuessResult;
};

export type RangeOption = {
  min: number;
  max: number;
  label: string;
};

export const ONE_PLAYER_RANGE: RangeOption = {
  min: 0,
  max: 100,
  label: '0 – 100',
};

export const TWO_PLAYER_RANGES: RangeOption[] = [
  { min: 0, max: 100, label: '0 – 100' },
  { min: 0, max: 1000, label: '0 – 1,000' },
  { min: 0, max: 10000, label: '0 – 10,000' },
];

export const ONE_PLAYER_GUESS_LIMIT = 6;

export type GameMode = 'one-player' | 'offline' | 'online';
export type Role = 'thinker' | 'guesser';
export type Outcome = 'won' | 'lost' | 'conflict';

export type Session = {
  mode: GameMode;
  min: number;
  max: number;
  maxGuesses: number | null;
  localRole: Role;
  secret: number | null;
  guesses: Guess[];
  outcome: Outcome | null;
  computerGuess: number | null;
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

export const DEFAULT_SERVER_URL = 'http://localhost:3456';
