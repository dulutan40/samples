import { useEffect, useRef, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { GuessHistory, GuessSlots } from '../components/GuessHistory';
import { Screen } from '../components/Screen';
import { boundsFromFeedback, nextComputerGuess, remainingGuesses } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import type { GuessResult } from '../types';
import { colors, radius, space } from '../theme';

export function PlayThinkerScreen() {
  const { go, goHome, session, setSession } = useAppState();
  const [thinking, setThinking] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  if (!session || session.computerGuess == null) return null;

  const used = session.guesses.length;
  const left = remainingGuesses(session.maxGuesses, used);

  const respond = (result: GuessResult) => {
    if (thinking) return;

    const guesses = [...session.guesses, { value: session.computerGuess!, result }];

    if (result === 'correct') {
      setSession({ ...session, guesses, outcome: 'lost' });
      go('result');
      return;
    }

    const leftover = remainingGuesses(session.maxGuesses, guesses.length);
    if (leftover === 0) {
      setSession({ ...session, guesses, outcome: 'won' });
      go('result');
      return;
    }

    const bounds = boundsFromFeedback(session.min, session.max, guesses);
    if (!bounds.valid) {
      setSession({ ...session, guesses, outcome: 'conflict' });
      go('result');
      return;
    }

    const nextGuess = nextComputerGuess(session.min, session.max, guesses);
    setThinking(true);
    setSession({ ...session, guesses });

    timerRef.current = setTimeout(() => {
      setSession({
        ...session,
        guesses,
        computerGuess: nextGuess,
        outcome: nextGuess == null ? 'conflict' : null,
      });
      setThinking(false);
      if (nextGuess == null) {
        go('result');
      }
    }, 700);
  };

  return (
    <Screen
      eyebrow="One player"
      title="Hold the number in your head"
      subtitle={`The computer is guessing between ${session.min} and ${session.max}. Tell it how it did.`}
      onBack={goHome}
    >
      <View style={styles.meta}>
        {session.maxGuesses != null && left != null ? (
          <>
            <Text style={styles.metaLabel}>{left} guess{left === 1 ? '' : 'es'} left</Text>
            <GuessSlots total={session.maxGuesses} used={used} />
          </>
        ) : null}
      </View>

      <View style={styles.guessCard}>
        <Text style={styles.guessLabel}>{thinking ? 'Thinking…' : 'Computer guesses'}</Text>
        <Text style={styles.guessValue}>{thinking ? '—' : session.computerGuess}</Text>
      </View>

      <View style={styles.actions}>
        <Button
          label="Guess is lower"
          variant="secondary"
          onPress={() => respond('lower')}
          disabled={thinking}
        />
        <Button label="Correct" onPress={() => respond('correct')} disabled={thinking} />
        <Button
          label="Guess is higher"
          variant="secondary"
          onPress={() => respond('higher')}
          disabled={thinking}
        />
      </View>

      <View style={styles.history}>
        <GuessHistory guesses={session.guesses} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  meta: {
    gap: space.sm,
    marginBottom: space.lg,
  },
  metaLabel: {
    color: colors.muted,
    fontSize: 15,
  },
  guessCard: {
    backgroundColor: colors.card,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.line,
    alignItems: 'center',
    paddingVertical: space.xl,
    marginBottom: space.lg,
  },
  guessLabel: {
    color: colors.gold,
    letterSpacing: 1.6,
    textTransform: 'uppercase',
    fontSize: 12,
    fontWeight: '700',
    marginBottom: space.sm,
  },
  guessValue: {
    color: colors.ink,
    fontSize: 64,
    fontWeight: '700',
    letterSpacing: -2,
    fontVariant: ['tabular-nums'],
  },
  actions: {
    gap: space.sm,
  },
  history: {
    marginTop: space.lg,
  },
});
