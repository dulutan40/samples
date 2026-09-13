import { useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { FeedbackLegend, FeedbackToggle, FeedbackView } from '../components/FeedbackView';
import { GuessHistory } from '../components/GuessHistory';
import { CodeDisplay, NumberPad } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { formatNumeric, isValidCode } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { submitGuess } from '../online/client';
import { colors, space } from '../theme';

export function OnlinePlayScreen() {
  const { goHome, session, online, feedbackMode, setFeedbackMode } = useAppState();
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  if (!session) return null;

  const waitingForSecret = online.phase === 'secret' && session.localRole === 'guesser';
  const last = session.guesses[session.guesses.length - 1];

  const submit = () => {
    if (!isValidCode(value, session.length)) {
      setError(`Guess ${session.length} different digits.`);
      return;
    }
    setError(null);
    setValue('');
    submitGuess(value);
  };

  return (
    <Screen
      eyebrow="Online"
      title={session.localRole === 'guesser' ? 'Your turn to guess' : 'They are guessing'}
      subtitle={`A ${session.length}-digit code with no repeated digits. There is no guess limit.`}
      onBack={goHome}
      scroll={false}
      headerRight={<FeedbackToggle mode={feedbackMode} onChange={setFeedbackMode} />}
    >
      {waitingForSecret ? (
        <View style={styles.wait}>
          <ActivityIndicator color={colors.accent} />
          <Text style={styles.waitText}>The other player is thinking of a number…</Text>
        </View>
      ) : (
        <>
          <View style={styles.meta}>
            <Text style={styles.metaLabel}>
              {session.guesses.length} guess{session.guesses.length === 1 ? '' : 'es'} so far
            </Text>
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
        </>
      )}

      {session.localRole === 'guesser' && !waitingForSecret ? (
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
