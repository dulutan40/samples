import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { ChoiceCard } from '../components/ChoiceCard';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { TWO_PLAYER_RANGES, type RangeOption } from '../types';
import { colors, radius, space } from '../theme';

export function OfflineSetupScreen() {
  const { go, setSession } = useAppState();
  const [range, setRange] = useState<RangeOption>(TWO_PLAYER_RANGES[0]);
  const [playerOneThinks, setPlayerOneThinks] = useState(true);

  const start = () => {
    const thinkerName = playerOneThinks ? 'Player 1' : 'Player 2';
    const guesserName = playerOneThinks ? 'Player 2' : 'Player 1';
    setSession({
      mode: 'offline',
      min: range.min,
      max: range.max,
      maxGuesses: null,
      localRole: 'guesser',
      secret: null,
      guesses: [],
      outcome: null,
      computerGuess: null,
      thinkerName,
      guesserName,
    });
    go('secretEntry');
  };

  return (
    <Screen
      eyebrow="Offline"
      title="Set up the match"
      subtitle="Pick a range, then decide who thinks of the secret. There is no guess limit."
      onBack={() => go('twoPlayerMode')}
    >
      <Text style={styles.section}>Range</Text>
      <View style={styles.pills}>
        {TWO_PLAYER_RANGES.map((option) => {
          const selected = option.max === range.max;
          return (
            <Pressable
              key={option.label}
              onPress={() => setRange(option)}
              style={[styles.pill, selected && styles.pillOn]}
            >
              <Text style={[styles.pillLabel, selected && styles.pillLabelOn]}>{option.label}</Text>
            </Pressable>
          );
        })}
      </View>

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
    marginTop: space.sm,
  },
  pills: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: space.sm,
    marginBottom: space.lg,
  },
  pill: {
    borderRadius: radius.pill,
    borderWidth: 1,
    borderColor: colors.line,
    backgroundColor: colors.card,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  pillOn: {
    backgroundColor: colors.gold,
    borderColor: colors.gold,
  },
  pillLabel: {
    color: colors.ink,
    fontWeight: '700',
  },
  pillLabelOn: {
    color: colors.bg,
  },
  stack: {
    gap: space.md,
  },
  cta: {
    marginTop: space.xl,
  },
});
