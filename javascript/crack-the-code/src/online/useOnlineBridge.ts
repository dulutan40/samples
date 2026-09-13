import { useEffect } from 'react';
import { useAppState } from '../navigation/AppState';
import { disconnectFromServer, setOnlineHandlers } from './client';

export function useOnlineBridge() {
  const { go, setOnline, setSession, setDigitLength } = useAppState();

  useEffect(() => {
    setOnlineHandlers({
      onRoomCreated: ({ passcode }) => {
        setOnline((current) => ({
          ...current,
          passcode,
          isHost: true,
          phase: 'waiting',
          playerCount: 1,
          error: null,
        }));
      },
      onRoomJoined: ({ passcode, isHost, playerCount }) => {
        setOnline((current) => ({
          ...current,
          passcode,
          isHost,
          playerCount,
          phase: playerCount >= 2 ? 'setup' : 'waiting',
          error: null,
        }));
        if (playerCount >= 2) {
          go('onlineSetup');
        }
      },
      onPlayerJoined: ({ playerCount }) => {
        setOnline((current) => ({
          ...current,
          playerCount,
          phase: playerCount >= 2 ? 'setup' : current.phase,
          error: null,
        }));
      },
      onRoomLocked: () => {
        setOnline((current) => ({ ...current, phase: 'setup', playerCount: 2 }));
        go('onlineSetup');
      },
      onAwaitingSetup: () => {
        setSession(null);
        setOnline((current) => ({ ...current, phase: 'setup', error: null }));
        go('onlineSetup');
      },
      onGameSetup: ({ length, role }) => {
        setDigitLength(length);
        setSession({
          mode: 'online',
          length,
          maxGuesses: null,
          localRole: role,
          secret: null,
          guesses: [],
          outcome: null,
          computerGuess: null,
          thinkerName: role === 'thinker' ? 'You' : 'Opponent',
          guesserName: role === 'guesser' ? 'You' : 'Opponent',
        });
        setOnline((current) => ({ ...current, phase: 'secret', error: null }));
        go(role === 'thinker' ? 'onlineSecret' : 'onlinePlay');
      },
      onAwaitingSecret: () => {
        setOnline((current) => ({ ...current, phase: 'secret' }));
      },
      onGameStarted: () => {
        setOnline((current) => ({ ...current, phase: 'playing' }));
        go('onlinePlay');
      },
      onGuessMade: ({ guesses }) => {
        setSession((current) => (current ? { ...current, guesses } : current));
      },
      onGameOver: ({ guesses, secret, guesserWon }) => {
        setSession((current) =>
          current
            ? {
                ...current,
                guesses,
                secret,
                outcome:
                  current.localRole === 'guesser'
                    ? guesserWon
                      ? 'won'
                      : 'lost'
                    : guesserWon
                      ? 'lost'
                      : 'won',
              }
            : current,
        );
        setOnline((current) => ({ ...current, phase: 'finished' }));
        go('onlineResult');
      },
      onOpponentLeft: ({ message }) => {
        disconnectFromServer();
        setOnline((current) => ({
          ...current,
          phase: 'error',
          error: message,
          passcode: null,
          playerCount: 0,
          isHost: false,
        }));
        setSession(null);
        go('onlineMenu');
      },
      onError: ({ message }) => {
        setOnline((current) => ({ ...current, phase: 'error', error: message }));
      },
      onDisconnect: () => {
        setOnline((current) => {
          if (current.phase === 'idle') return current;
          return {
            ...current,
            phase: current.phase === 'connecting' ? 'error' : current.phase,
          };
        });
      },
    });
  }, [go, setDigitLength, setOnline, setSession]);
}
