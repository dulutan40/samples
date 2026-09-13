import { StyleSheet, Text, View } from 'react-native';
import { ChoiceCard } from '../components/ChoiceCard';
import { LengthPills } from '../components/LengthPills';
import { Screen } from '../components/Screen';
import { nextComputerGuess, pickSecret } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { guessLimitFor } from '../types';
import { colors, space } from '../theme';

export function OnePlayerRoleScreen() {
  const { go, digitLength, setDigitLength, setSession } = useAppState();
  const limit = guessLimitFor(digitLength);

  const startAsThinker = () => {
    setSession({
      mode: 'one-player',
      length: digitLength,
      maxGuesses: limit,
      localRole: 'thinker',
      secret: null,
      guesses: [],
      outcome: null,
      computerGuess: nextComputerGuess(digitLength, []),
      thinkerName: 'You',
      guesserName: 'Computer',
    });
    go('playThinker');
  };

  const startAsGuesser = () => {
    setSession({
      mode: 'one-player',
      length: digitLength,
      maxGuesses: limit,
      localRole: 'guesser',
      secret: pickSecret(digitLength),
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
      subtitle={`A ${digitLength}-digit code, no repeated digits. The guesser has ${limit} tries.`}
      onBack={() => go('home')}
    >
      <Text style={styles.section}>Code length</Text>
      <LengthPills value={digitLength} onChange={setDigitLength} />
      <View style={styles.stack}>
        <ChoiceCard
          title="I am thinking of a number"
          description="The computer guesses. After each try, you report pluses and minuses."
          onPress={startAsThinker}
        />
        <ChoiceCard
          title="I will guess"
          description="The computer hides a code. You get plus and minus marks after each try."
          onPress={startAsGuesser}
        />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  section: {
    color: colors.muted,
    fontSize: 13,
    fontWeight: '700',
    letterSpacing: 1.2,
    textTransform: 'uppercase',
    marginBottom: space.sm,
  },
  stack: {
    gap: space.md,
    marginTop: space.xl,
  },
});
