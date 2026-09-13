import { StyleSheet, View } from 'react-native';
import { Button } from '../components/Button';
import { FeedbackToggle } from '../components/FeedbackView';
import { GuessHistory } from '../components/GuessHistory';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { space } from '../theme';

export function ResultScreen() {
  const { go, goHome, session, feedbackMode, setFeedbackMode } = useAppState();

  if (!session || !session.outcome) return null;

  const tries = session.guesses.length;
  let title = 'Round complete';
  let subtitle = '';

  if (session.outcome === 'conflict') {
    title = 'Those marks do not add up';
    subtitle = 'No code matches the plus and minus scores you gave. Check the secret and try again.';
  } else if (session.localRole === 'guesser') {
    if (session.outcome === 'won') {
      title = 'You cracked it';
      subtitle =
        session.secret != null
          ? `The code was ${session.secret}. It took ${tries} guess${tries === 1 ? '' : 'es'}.`
          : `It took ${tries} guess${tries === 1 ? '' : 'es'}.`;
    } else {
      title = 'Out of guesses';
      subtitle =
        session.secret != null
          ? `The code was ${session.secret}.`
          : 'The guesses ran out before the code was found.';
    }
  } else if (session.outcome === 'won') {
    title = 'The computer ran out';
    subtitle = 'Your code stayed hidden.';
  } else {
    title = 'The computer got it';
    subtitle = `It needed ${tries} guess${tries === 1 ? '' : 'es'}.`;
  }

  const playAgain = () => {
    if (session.mode === 'one-player') {
      go('onePlayerRole');
      return;
    }
    go('offlineSetup');
  };

  return (
    <Screen
      eyebrow="Match over"
      title={title}
      subtitle={subtitle}
      headerRight={<FeedbackToggle mode={feedbackMode} onChange={setFeedbackMode} />}
    >
      <GuessHistory guesses={session.guesses} length={session.length} mode={feedbackMode} />
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
