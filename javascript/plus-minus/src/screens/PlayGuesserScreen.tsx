import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { FeedbackLegend, FeedbackToggle, FeedbackView } from '../components/FeedbackView';
import { GuessHistory, GuessSlots } from '../components/GuessHistory';
import { CodeDisplay, NumberPad } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { evaluateGuess, formatNumeric, isValidCode, isWon, remainingGuesses } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { colors, space } from '../theme';

export function PlayGuesserScreen() {
  const { go, goHome, session, setSession, feedbackMode, setFeedbackMode } = useAppState();
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  if (!session || session.secret == null) return null;

  const used = session.guesses.length;
  const left = remainingGuesses(session.maxGuesses, used);
  const last = session.guesses[session.guesses.length - 1];

  const submit = () => {
    if (!isValidCode(value, session.length)) {
      setError(`Guess ${session.length} different digits.`);
      return;
    }

    const feedback = evaluateGuess(session.secret!, value);
    const guesses = [...session.guesses, { value, ...feedback }];
    const nextLeft = remainingGuesses(session.maxGuesses, guesses.length);
    const outcome = isWon(feedback, session.length) ? 'won' : nextLeft === 0 ? 'lost' : null;

    setSession({ ...session, guesses, outcome });
    setValue('');
    setError(null);

    if (outcome) {
      go('result');
    }
  };

  return (
    <Screen
      eyebrow={session.mode === 'one-player' ? 'One player' : 'Offline'}
      title={`${session.guesserName} is guessing`}
      subtitle={`Find the ${session.length}-digit code. Digits do not repeat.`}
      onBack={goHome}
      scroll={false}
      headerRight={<FeedbackToggle mode={feedbackMode} onChange={setFeedbackMode} />}
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
        {last ? (
          <View style={styles.flash}>
            <FeedbackView feedback={last} length={session.length} mode={feedbackMode} />
            {feedbackMode === 'color' ? (
              <Text style={styles.flashHint}>{formatNumeric(last)}</Text>
            ) : null}
          </View>
        ) : null}
        <FeedbackLegend mode={feedbackMode} />
      </View>

      <GuessHistory guesses={session.guesses} length={session.length} mode={feedbackMode} />

      <View style={styles.pad}>
        <CodeDisplay value={value} length={session.length} />
        {error ? <Text style={styles.error}>{error}</Text> : null}
        <NumberPad
          value={value}
          onChange={(next) => {
            setValue(next);
            setError(null);
          }}
          onSubmit={submit}
          length={session.length}
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
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.md,
  },
  flashHint: {
    color: colors.muted,
    fontSize: 13,
  },
  pad: {
    marginTop: 'auto',
    paddingBottom: space.lg,
  },
  error: {
    color: colors.miss,
    marginBottom: space.md,
    textAlign: 'center',
  },
});
