import { StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { GuessHistory } from '../components/GuessHistory';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { space } from '../theme';

export function ResultScreen() {
  const { go, goHome, session } = useAppState();

  if (!session || !session.outcome) return null;

  const tries = session.guesses.length;
  const last = session.guesses[session.guesses.length - 1];

  let eyebrow = 'Match over';
  let title = 'Round complete';
  let subtitle = '';

  if (session.outcome === 'conflict') {
    title = 'The hints did not add up';
    subtitle =
      'Those higher and lower answers left no possible number. Check the secret and try again.';
  } else if (session.localRole === 'guesser') {
    if (session.outcome === 'won') {
      title = 'You found it';
      subtitle =
        session.secret != null
          ? `The number was ${session.secret}. It took ${tries} guess${tries === 1 ? '' : 'es'}.`
          : `It took ${tries} guess${tries === 1 ? '' : 'es'}.`;
    } else {
      title = 'Out of guesses';
      subtitle =
        session.secret != null
          ? `The number was ${session.secret}. ${last ? `Your last try was ${last.value}.` : ''}`
          : 'Six guesses was not enough this time.';
    }
  } else if (session.outcome === 'won') {
    title = 'The computer ran out';
    subtitle = 'Your number stayed hidden after six guesses.';
  } else {
    title = 'The computer got it';
    subtitle = `It needed ${tries} guess${tries === 1 ? '' : 'es'}.`;
  }

  const playAgain = () => {
    if (session.mode === 'one-player') {
      go('onePlayerRole');
      return;
    }
    if (session.mode === 'offline') {
      go('offlineSetup');
    }
  };

  return (
    <Screen eyebrow={eyebrow} title={title} subtitle={subtitle}>
      <GuessHistory guesses={session.guesses} />
      <View style={styles.actions}>
        <Button label="Play again" onPress={playAgain} />
        <Button label="Home" variant="secondary" onPress={goHome} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  actions: {
    marginTop: space.xl,
    gap: space.sm,
  },
});
