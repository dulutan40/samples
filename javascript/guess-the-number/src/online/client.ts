import { io, type Socket } from 'socket.io-client';
import type { Guess, Role } from '../types';

export type RoomCreatedPayload = { passcode: string };
export type RoomJoinedPayload = { passcode: string; isHost: boolean; playerCount: number };
export type GameSetupPayload = { min: number; max: number; role: Role };
export type GuessMadePayload = { guesses: Guess[] };
export type GameOverPayload = { guesses: Guess[]; secret: number; guesserWon: boolean };
export type RoomErrorPayload = { message: string };

type Handlers = {
  onRoomCreated?: (payload: RoomCreatedPayload) => void;
  onRoomJoined?: (payload: RoomJoinedPayload) => void;
  onPlayerJoined?: (payload: { playerCount: number }) => void;
  onRoomLocked?: () => void;
  onGameSetup?: (payload: GameSetupPayload) => void;
  onAwaitingSetup?: () => void;
  onAwaitingSecret?: () => void;
  onGameStarted?: () => void;
  onGuessMade?: (payload: GuessMadePayload) => void;
  onGameOver?: (payload: GameOverPayload) => void;
  onOpponentLeft?: (payload: { message: string }) => void;
  onError?: (payload: RoomErrorPayload) => void;
  onDisconnect?: () => void;
};

let socket: Socket | null = null;
let handlers: Handlers = {};

function bind(next: Socket) {
  next.on('roomCreated', (payload) => handlers.onRoomCreated?.(payload));
  next.on('roomJoined', (payload) => handlers.onRoomJoined?.(payload));
  next.on('playerJoined', (payload) => handlers.onPlayerJoined?.(payload));
  next.on('roomLocked', () => handlers.onRoomLocked?.());
  next.on('gameSetup', (payload) => handlers.onGameSetup?.(payload));
  next.on('awaitingSetup', () => handlers.onAwaitingSetup?.());
  next.on('awaitingSecret', () => handlers.onAwaitingSecret?.());
  next.on('gameStarted', () => handlers.onGameStarted?.());
  next.on('guessMade', (payload) => handlers.onGuessMade?.(payload));
  next.on('gameOver', (payload) => handlers.onGameOver?.(payload));
  next.on('opponentLeft', (payload) => handlers.onOpponentLeft?.(payload));
  next.on('roomError', (payload) => handlers.onError?.(payload));
  next.on('disconnect', () => handlers.onDisconnect?.());
  next.on('connect_error', () => {
    handlers.onError?.({
      message: 'Could not reach the room server. Check the address and that the server is running.',
    });
  });
}

export function setOnlineHandlers(next: Handlers) {
  handlers = next;
}

export function connectToServer(url: string): Socket {
  if (socket) {
    socket.removeAllListeners();
    socket.disconnect();
    socket = null;
  }
  socket = io(url, {
    transports: ['websocket'],
    timeout: 5000,
  });
  bind(socket);
  return socket;
}

export function disconnectFromServer() {
  if (socket) {
    socket.removeAllListeners();
    socket.disconnect();
    socket = null;
  }
}

export function getSocket(): Socket | null {
  return socket;
}

export function createRoom() {
  socket?.emit('createRoom');
}

export function joinRoom(passcode: string) {
  socket?.emit('joinRoom', { passcode });
}

export function setupGame(min: number, max: number, hostThinks: boolean) {
  socket?.emit('setupGame', { min, max, hostThinks });
}

export function submitSecret(secret: number) {
  socket?.emit('submitSecret', { secret });
}

export function submitGuess(value: number) {
  socket?.emit('submitGuess', { value });
}

export function requestPlayAgain() {
  socket?.emit('playAgain');
}
