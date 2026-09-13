import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { GuessHistory, GuessSlots } from '../components/GuessHistory';
import { NumberPad, ValueDisplay } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { evaluateGuess, isInRange, remainingGuesses, resultCopy } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { colors, space } from '../theme';

export function PlayGuesserScreen() {
  const { go, goHome, session, setSession } = useAppState();
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [flash, setFlash] = useState<string | null>(null);

  if (!session || session.secret == null) return null;

  const used = session.guesses.length;
  const left = remainingGuesses(session.maxGuesses, used);

  const submit = () => {
    const guess = Number(value);
    if (!isInRange(guess, session.min, session.max)) {
      setError(`Guess a whole number from ${session.min} to ${session.max}.`);
      return;
    }

    const result = evaluateGuess(guess, session.secret!);
    const guesses = [...session.guesses, { value: guess, result }];
    const nextLeft = remainingGuesses(session.maxGuesses, guesses.length);
    const outcome =
      result === 'correct' ? 'won' : nextLeft === 0 ? 'lost' : null;

    setSession({ ...session, guesses, outcome });
    setValue('');
    setError(null);
    setFlash(resultCopy(result).title);

    if (outcome) {
      go('result');
    }
  };

  return (
    <Screen
      eyebrow={session.mode === 'one-player' ? 'One player' : 'Offline'}
      title={`${session.guesserName} is guessing`}
      subtitle={`Find the number between ${session.min} and ${session.max}.`}
      onBack={goHome}
      scroll={false}
    >
      <View style={styles.meta}>
        {session.maxGuesses != null && left != null ? (
          <>
            <Text style={styles.metaLabel}>{left} guess{left === 1 ? '' : 'es'} left</Text>
            <GuessSlots total={session.maxGuesses} used={used} />
          </>
        ) : (
          <Text style={styles.metaLabel}>{used} guess{used === 1 ? '' : 'es'} so far · no limit</Text>
        )}
        {flash ? <Text style={styles.flash}>{flash}</Text> : null}
      </View>

      <GuessHistory guesses={session.guesses} />

      <View style={styles.pad}>
        <ValueDisplay value={value} placeholder="Your guess" />
        {error ? <Text style={styles.error}>{error}</Text> : null}
        <NumberPad
          value={value}
          onChange={(next) => {
            setValue(next);
            setError(null);
          }}
          onSubmit={submit}
          maxLength={String(session.max).length}
          submitLabel="Guess"
        />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  meta: {
    gap: space.sm,
    marginBottom: space.md,
  },
  metaLabel: {
    color: colors.muted,
    fontSize: 15,
  },
  flash: {
    color: colors.gold,
    fontSize: 20,
    fontWeight: '700',
  },
  pad: {
    marginTop: 'auto',
    paddingBottom: space.lg,
  },
  error: {
    color: colors.rose,
    marginBottom: space.md,
    textAlign: 'center',
  },
});
