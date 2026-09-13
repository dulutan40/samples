import { useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { GuessHistory } from '../components/GuessHistory';
import { NumberPad, ValueDisplay } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { isInRange, resultCopy } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { submitGuess } from '../online/client';
import { colors, space } from '../theme';

export function OnlinePlayScreen() {
  const { goHome, session, online } = useAppState();
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  if (!session) return null;

  const waitingForSecret = online.phase === 'secret' && session.localRole === 'guesser';
  const last = session.guesses[session.guesses.length - 1];

  const submit = () => {
    const guess = Number(value);
    if (!isInRange(guess, session.min, session.max)) {
      setError(`Guess a whole number from ${session.min} to ${session.max}.`);
      return;
    }
    setError(null);
    setValue('');
    submitGuess(guess);
  };

  return (
    <Screen
      eyebrow="Online"
      title={session.localRole === 'guesser' ? 'Your turn to guess' : 'They are guessing'}
      subtitle={`The number is between ${session.min} and ${session.max}. There is no guess limit.`}
      onBack={goHome}
      scroll={false}
    >
      {waitingForSecret ? (
        <View style={styles.wait}>
          <ActivityIndicator color={colors.gold} />
          <Text style={styles.waitText}>The other player is thinking of a number…</Text>
        </View>
      ) : (
        <>
          <View style={styles.meta}>
            <Text style={styles.metaLabel}>
              {session.guesses.length} guess{session.guesses.length === 1 ? '' : 'es'} so far
            </Text>
            {last ? <Text style={styles.flash}>{resultCopy(last.result).title}</Text> : null}
          </View>
          <GuessHistory guesses={session.guesses} />
        </>
      )}

      {session.localRole === 'guesser' && !waitingForSecret ? (
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
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  wait: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.md,
    marginTop: space.md,
  },
  waitText: {
    color: colors.ink,
    flex: 1,
    fontSize: 16,
  },
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
