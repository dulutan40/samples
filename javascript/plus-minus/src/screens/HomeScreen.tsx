import { StyleSheet, Text, View } from 'react-native';
import { ChoiceCard } from '../components/ChoiceCard';
import { LengthPills } from '../components/LengthPills';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { colors, space } from '../theme';

export function HomeScreen() {
  const { go, digitLength, setDigitLength } = useAppState();

  return (
    <Screen
      eyebrow="Mastermind, with digits"
      title="Plus Minus"
      subtitle="Someone hides a code with unique digits. Each guess scores pluses for right place and minuses for right digit, wrong place."
    >
      <Text style={styles.section}>Code length</Text>
      <LengthPills value={digitLength} onChange={setDigitLength} />
      <View style={styles.stack}>
        <ChoiceCard
          title="One player"
          description="Play the computer. Decide who thinks of the code."
          onPress={() => go('onePlayerRole')}
        />
        <ChoiceCard
          title="Two players"
          description="Same device, or meet in a room with a passcode."
          onPress={() => go('twoPlayerMode')}
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
