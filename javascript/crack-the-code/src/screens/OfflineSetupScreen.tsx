import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { ChoiceCard } from '../components/ChoiceCard';
import { LengthPills } from '../components/LengthPills';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { colors, space } from '../theme';

export function OfflineSetupScreen() {
  const { go, digitLength, setDigitLength, setSession } = useAppState();
  const [playerOneThinks, setPlayerOneThinks] = useState(true);

  const start = () => {
    setSession({
      mode: 'offline',
      length: digitLength,
      maxGuesses: null,
      localRole: 'guesser',
      secret: null,
      guesses: [],
      outcome: null,
      computerGuess: null,
      thinkerName: playerOneThinks ? 'Player 1' : 'Player 2',
      guesserName: playerOneThinks ? 'Player 2' : 'Player 1',
    });
    go('secretEntry');
  };

  return (
    <Screen
      eyebrow="Offline"
      title="Set up the match"
      subtitle="Pick a length and who thinks of the code. Digits cannot repeat. There is no guess limit."
      onBack={() => go('twoPlayerMode')}
    >
      <Text style={styles.section}>Code length</Text>
      <LengthPills value={digitLength} onChange={setDigitLength} />

      <Text style={styles.section}>Who thinks of the number?</Text>
      <View style={styles.stack}>
        <ChoiceCard
          title="Player 1 thinks"
          description="Player 1 enters a secret. Player 2 guesses on this device."
          selected={playerOneThinks}
          onPress={() => setPlayerOneThinks(true)}
        />
        <ChoiceCard
          title="Player 2 thinks"
          description="Player 2 enters a secret. Player 1 guesses on this device."
          selected={!playerOneThinks}
          onPress={() => setPlayerOneThinks(false)}
        />
      </View>

      <View style={styles.cta}>
        <Button label="Continue" onPress={start} />
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
    marginTop: space.md,
  },
  stack: {
    gap: space.md,
  },
  cta: {
    marginTop: space.xl,
  },
});
