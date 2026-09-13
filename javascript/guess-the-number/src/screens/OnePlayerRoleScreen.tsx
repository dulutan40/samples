import { StyleSheet, View } from 'react-native';
import { ChoiceCard } from '../components/ChoiceCard';
import { Screen } from '../components/Screen';
import { nextComputerGuess, pickSecret } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { ONE_PLAYER_GUESS_LIMIT, ONE_PLAYER_RANGE } from '../types';
import { space } from '../theme';

export function OnePlayerRoleScreen() {
  const { go, setSession } = useAppState();

  const startAsThinker = () => {
    setSession({
      mode: 'one-player',
      min: ONE_PLAYER_RANGE.min,
      max: ONE_PLAYER_RANGE.max,
      maxGuesses: ONE_PLAYER_GUESS_LIMIT,
      localRole: 'thinker',
      secret: null,
      guesses: [],
      outcome: null,
      computerGuess: nextComputerGuess(ONE_PLAYER_RANGE.min, ONE_PLAYER_RANGE.max, []),
      thinkerName: 'You',
      guesserName: 'Computer',
    });
    go('playThinker');
  };

  const startAsGuesser = () => {
    setSession({
      mode: 'one-player',
      min: ONE_PLAYER_RANGE.min,
      max: ONE_PLAYER_RANGE.max,
      maxGuesses: ONE_PLAYER_GUESS_LIMIT,
      localRole: 'guesser',
      secret: pickSecret(ONE_PLAYER_RANGE.min, ONE_PLAYER_RANGE.max),
      guesses: [],
      outcome: null,
      computerGuess: null,
      thinkerName: 'Computer',
      guesserName: 'You',
    });
    go('playGuesser');
  };

  return (
    <Screen
      eyebrow="One player"
      title="Who is thinking?"
      subtitle="Someone holds a number between 0 and 100. The other has six guesses."
      onBack={() => go('home')}
    >
      <View style={styles.stack}>
        <ChoiceCard
          title="I am thinking of a number"
          description="The computer will guess. After each try, say if it is too low, too high, or correct."
          onPress={startAsThinker}
        />
        <ChoiceCard
          title="I will guess"
          description="The computer picks a secret. You have six chances to find it."
          onPress={startAsGuesser}
        />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  stack: {
    gap: space.md,
  },
});
