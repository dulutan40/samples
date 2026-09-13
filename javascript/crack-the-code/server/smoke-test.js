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

function evaluateGuess(secret, guess) {
  let plus = 0;
  const secretRest = [];
  const guessRest = [];
  for (let i = 0; i < secret.length; i += 1) {
    if (secret[i] === guess[i]) plus += 1;
    else {
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

(async () => {
  const sample = evaluateGuess('12345', '42063');
  if (sample.plus !== 1 || sample.minus !== 2) {
    throw new Error(`expected +1 -2 for 12345 vs 42063, got +${sample.plus} -${sample.minus}`);
  }

  const host = io('http://localhost:3457', { transports: ['websocket'] });
  const guest = io('http://localhost:3457', { transports: ['websocket'] });
  await Promise.all([connected(host), connected(guest)]);

  host.emit('createRoom');
  const created = await once(host, 'roomCreated');

  const locked = once(host, 'roomLocked');
  guest.emit('joinRoom', { passcode: created.passcode });
  await once(guest, 'roomJoined');
  await locked;

  const late = io('http://localhost:3457', { transports: ['websocket'] });
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
  host.emit('setupGame', { length: 5, hostThinks: true });
  const [hostRole, guestRole] = await Promise.all([hostSetup, guestSetup]);
  if (hostRole.role !== 'thinker' || guestRole.length !== 5 || guestRole.role !== 'guesser') {
    throw new Error('setup payload wrong');
  }

  const started = Promise.all([once(host, 'gameStarted'), once(guest, 'gameStarted')]);
  host.emit('submitSecret', { secret: '12345' });
  await started;

  const over = once(guest, 'gameOver');
  guest.emit('submitGuess', { value: '42063' });
  const first = await once(guest, 'guessMade');
  if (first.guesses[0].plus !== 1 || first.guesses[0].minus !== 2) {
    throw new Error('expected +1 -2 on first guess');
  }
  guest.emit('submitGuess', { value: '12345' });
  const result = await over;
  if (!result.guesserWon || result.secret !== '12345') throw new Error('game over payload wrong');

  host.close();
  guest.close();
  console.log('crack-the-code smoke test passed');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
