import { StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { FeedbackToggle } from '../components/FeedbackView';
import { GuessHistory } from '../components/GuessHistory';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { requestPlayAgain } from '../online/client';
import { colors, space } from '../theme';

export function OnlineResultScreen() {
  const { goHome, session, online, feedbackMode, setFeedbackMode } = useAppState();

  if (!session || !session.outcome) return null;

  const tries = session.guesses.length;
  const guessedIt =
    (session.localRole === 'guesser' && session.outcome === 'won') ||
    (session.localRole === 'thinker' && session.outcome === 'lost');

  const title = guessedIt
    ? session.localRole === 'guesser'
      ? 'You cracked it'
      : 'They cracked it'
    : 'Round over';

  const subtitle =
    session.secret != null
      ? `The code was ${session.secret}. It took ${tries} guess${tries === 1 ? '' : 'es'}.`
      : `It took ${tries} guess${tries === 1 ? '' : 'es'}.`;

  return (
    <Screen
      eyebrow="Online"
      title={title}
      subtitle={subtitle}
      headerRight={<FeedbackToggle mode={feedbackMode} onChange={setFeedbackMode} />}
    >
      <GuessHistory guesses={session.guesses} length={session.length} mode={feedbackMode} />
      {online.error ? <Text style={styles.error}>{online.error}</Text> : null}
      <View style={styles.actions}>
        {online.isHost ? (
          <Button label="Play again" onPress={requestPlayAgain} />
        ) : (
          <Text style={styles.wait}>Waiting for the host to start another round…</Text>
        )}
        <Button label="Leave room" variant="secondary" onPress={goHome} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  actions: {
    marginTop: space.xl,
    gap: space.sm,
  },
  wait: {
    color: colors.muted,
    textAlign: 'center',
    marginBottom: space.sm,
  },
  error: {
    color: colors.miss,
    marginTop: space.md,
  },
});
