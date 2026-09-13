const { io } = require('socket.io-client');

function once(socket, event) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('timeout waiting for ' + event)), 4000);
    socket.once(event, (payload) => {
      clearTimeout(timer);
      resolve(payload);
    });
    socket.once('roomError', (payload) => {
      clearTimeout(timer);
      reject(new Error(payload.message));
    });
  });
}

async function connected(socket) {
  if (socket.connected) return;
  await new Promise((resolve, reject) => {
    socket.once('connect', resolve);
    socket.once('connect_error', reject);
  });
}

(async () => {
  const host = io('http://localhost:3456', { transports: ['websocket'] });
  const guest = io('http://localhost:3456', { transports: ['websocket'] });
  await Promise.all([connected(host), connected(guest)]);

  host.emit('createRoom');
  const created = await once(host, 'roomCreated');
  if (!/^\d{4}$/.test(created.passcode)) throw new Error('bad passcode');

  const locked = once(host, 'roomLocked');
  guest.emit('joinRoom', { passcode: created.passcode });
  const joined = await once(guest, 'roomJoined');
  await locked;
  if (joined.playerCount !== 2 || joined.isHost) throw new Error('join payload wrong');

  const late = io('http://localhost:3456', { transports: ['websocket'] });
  await connected(late);
  late.emit('joinRoom', { passcode: created.passcode });
  try {
    await once(late, 'roomJoined');
    throw new Error('locked room should reject a third player');
  } catch (error) {
    if (!String(error.message).includes('locked')) throw error;
  }
  late.close();

  const hostSetup = once(host, 'gameSetup');
  const guestSetup = once(guest, 'gameSetup');
  host.emit('setupGame', { min: 0, max: 100, hostThinks: true });
  const [hostRole, guestRole] = await Promise.all([hostSetup, guestSetup]);
  if (hostRole.role !== 'thinker' || guestRole.role !== 'guesser') {
    throw new Error('roles are swapped');
  }

  const started = Promise.all([once(host, 'gameStarted'), once(guest, 'gameStarted')]);
  host.emit('submitSecret', { secret: 42 });
  await started;

  const over = once(guest, 'gameOver');
  guest.emit('submitGuess', { value: 10 });
  const first = await once(guest, 'guessMade');
  if (first.guesses[0].result !== 'lower') throw new Error('expected lower');
  guest.emit('submitGuess', { value: 42 });
  const result = await over;
  if (!result.guesserWon || result.secret !== 42) throw new Error('game over payload wrong');

  host.close();
  guest.close();
  console.log('online room smoke test passed');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
