import { StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { GuessHistory } from '../components/GuessHistory';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { requestPlayAgain } from '../online/client';
import { colors, space } from '../theme';

export function OnlineResultScreen() {
  const { goHome, session, online } = useAppState();

  if (!session || !session.outcome) return null;

  const tries = session.guesses.length;
  const guessedIt =
    (session.localRole === 'guesser' && session.outcome === 'won') ||
    (session.localRole === 'thinker' && session.outcome === 'lost');

  const title = guessedIt
    ? session.localRole === 'guesser'
      ? 'You found it'
      : 'They found it'
    : 'Round over';

  const subtitle =
    session.secret != null
      ? `The number was ${session.secret}. It took ${tries} guess${tries === 1 ? '' : 'es'}.`
      : `It took ${tries} guess${tries === 1 ? '' : 'es'}.`;

  return (
    <Screen eyebrow="Online" title={title} subtitle={subtitle}>
      <GuessHistory guesses={session.guesses} />
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
    color: colors.rose,
    marginTop: space.md,
  },
});
