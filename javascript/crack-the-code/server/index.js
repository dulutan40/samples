const http = require('http');
const cors = require('cors');
const express = require('express');
const { Server } = require('socket.io');

const PORT = Number(process.env.PORT) || 3457;

function evaluateGuess(secret, guess) {
  let plus = 0;
  const secretRest = [];
  const guessRest = [];

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

function isValidCode(code, length) {
  return typeof code === 'string' && code.length === length && /^\d+$/.test(code) && new Set(code).size === length;
}

/** @typedef {{
 *  passcode: string,
 *  hostId: string,
 *  guestId: string | null,
 *  locked: boolean,
 *  status: 'waiting' | 'setup' | 'secret' | 'playing' | 'finished',
 *  length: number | null,
 *  thinkerId: string | null,
 *  guesserId: string | null,
 *  secret: string | null,
 *  guesses: { value: string, plus: number, minus: number }[]
 * }} Room */

/** @type {Map<string, Room>} */
const rooms = new Map();
/** @type {Map<string, string>} */
const socketToPasscode = new Map();

function generatePasscode() {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    const code = String(Math.floor(1000 + Math.random() * 9000));
    if (!rooms.has(code)) return code;
  }
  throw new Error('Could not allocate a passcode');
}

function getRoomForSocket(socketId) {
  const passcode = socketToPasscode.get(socketId);
  if (!passcode) return null;
  return rooms.get(passcode) ?? null;
}

function destroyRoom(io, room, message) {
  io.to(room.passcode).emit('opponentLeft', { message });
  for (const playerId of [room.hostId, room.guestId]) {
    if (!playerId) continue;
    const playerSocket = io.sockets.sockets.get(playerId);
    playerSocket?.leave(room.passcode);
    socketToPasscode.delete(playerId);
  }
  rooms.delete(room.passcode);
}

const app = express();
app.use(cors());
app.get('/health', (_req, res) => {
  res.json({ ok: true, rooms: rooms.size });
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' },
});

io.on('connection', (socket) => {
  socket.on('createRoom', () => {
    if (socketToPasscode.has(socket.id)) {
      socket.emit('roomError', { message: 'You are already in a room.' });
      return;
    }

    let passcode;
    try {
      passcode = generatePasscode();
    } catch {
      socket.emit('roomError', { message: 'Could not create a room. Try again.' });
      return;
    }

    /** @type {Room} */
    const room = {
      passcode,
      hostId: socket.id,
      guestId: null,
      locked: false,
      status: 'waiting',
      length: null,
      thinkerId: null,
      guesserId: null,
      secret: null,
      guesses: [],
    };

    rooms.set(passcode, room);
    socketToPasscode.set(socket.id, passcode);
    socket.join(passcode);
    socket.emit('roomCreated', { passcode });
  });

  socket.on('joinRoom', ({ passcode } = {}) => {
    const code = String(passcode ?? '').trim();
    const room = rooms.get(code);

    if (!room) {
      socket.emit('roomError', { message: 'No room uses that passcode.' });
      return;
    }
    if (room.locked || room.guestId) {
      socket.emit('roomError', { message: 'That room is locked. It already has two players.' });
      return;
    }
    if (room.hostId === socket.id) {
      socket.emit('roomError', { message: 'You already host this room.' });
      return;
    }

    room.guestId = socket.id;
    room.locked = true;
    room.status = 'setup';
    socketToPasscode.set(socket.id, code);
    socket.join(code);

    socket.emit('roomJoined', { passcode: code, isHost: false, playerCount: 2 });
    io.to(code).emit('playerJoined', { playerCount: 2 });
    io.to(code).emit('roomLocked');
  });

  socket.on('setupGame', ({ length, hostThinks } = {}) => {
    const room = getRoomForSocket(socket.id);
    if (!room) {
      socket.emit('roomError', { message: 'You are not in a room.' });
      return;
    }
    if (socket.id !== room.hostId) {
      socket.emit('roomError', { message: 'Only the host can set up the game.' });
      return;
    }
    if (!room.guestId || !room.locked) {
      socket.emit('roomError', { message: 'Wait for the second player before starting.' });
      return;
    }
    if (![3, 4, 5].includes(Number(length))) {
      socket.emit('roomError', { message: 'Choose a 3, 4, or 5-digit code.' });
      return;
    }

    room.length = Number(length);
    room.thinkerId = hostThinks ? room.hostId : room.guestId;
    room.guesserId = hostThinks ? room.guestId : room.hostId;
    room.secret = null;
    room.guesses = [];
    room.status = 'secret';

    for (const playerId of [room.hostId, room.guestId]) {
      const role = playerId === room.thinkerId ? 'thinker' : 'guesser';
      io.to(playerId).emit('gameSetup', { length: room.length, role });
    }
    io.to(room.passcode).emit('awaitingSecret');
  });

  socket.on('submitSecret', ({ secret } = {}) => {
    const room = getRoomForSocket(socket.id);
    if (!room || room.status !== 'secret' || room.length == null) {
      socket.emit('roomError', { message: 'It is not time to set a secret.' });
      return;
    }
    if (socket.id !== room.thinkerId) {
      socket.emit('roomError', { message: 'Only the thinker can set the secret.' });
      return;
    }
    const value = String(secret ?? '');
    if (!isValidCode(value, room.length)) {
      socket.emit('roomError', { message: `Enter ${room.length} different digits.` });
      return;
    }

    room.secret = value;
    room.status = 'playing';
    io.to(room.passcode).emit('gameStarted');
  });

  socket.on('submitGuess', ({ value } = {}) => {
    const room = getRoomForSocket(socket.id);
    if (!room || room.status !== 'playing' || room.secret == null || room.length == null) {
      socket.emit('roomError', { message: 'The match is not ready for guesses.' });
      return;
    }
    if (socket.id !== room.guesserId) {
      socket.emit('roomError', { message: 'Only the guesser can submit a guess.' });
      return;
    }
    const guess = String(value ?? '');
    if (!isValidCode(guess, room.length)) {
      socket.emit('roomError', { message: `Guess ${room.length} different digits.` });
      return;
    }

    const { plus, minus } = evaluateGuess(room.secret, guess);
    room.guesses.push({ value: guess, plus, minus });
    io.to(room.passcode).emit('guessMade', { guesses: room.guesses });

    if (plus === room.length) {
      room.status = 'finished';
      io.to(room.passcode).emit('gameOver', {
        guesses: room.guesses,
        secret: room.secret,
        guesserWon: true,
      });
    }
  });

  socket.on('playAgain', () => {
    const room = getRoomForSocket(socket.id);
    if (!room) return;
    if (socket.id !== room.hostId) {
      socket.emit('roomError', { message: 'Only the host can start another round.' });
      return;
    }
    if (!room.guestId) return;

    room.status = 'setup';
    room.length = null;
    room.thinkerId = null;
    room.guesserId = null;
    room.secret = null;
    room.guesses = [];

    io.to(room.passcode).emit('awaitingSetup');
  });

  socket.on('disconnect', () => {
    const room = getRoomForSocket(socket.id);
    socketToPasscode.delete(socket.id);
    if (!room) return;

    if (socket.id === room.hostId) {
      destroyRoom(io, room, 'The host left. The room is closed.');
      return;
    }
    if (socket.id === room.guestId) {
      destroyRoom(io, room, 'The other player left. The room is closed.');
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Crack the Code room server listening on http://0.0.0.0:${PORT}`);
});
