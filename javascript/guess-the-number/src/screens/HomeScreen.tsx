import { StyleSheet, Text, View } from 'react-native';
import { ChoiceCard } from '../components/ChoiceCard';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { colors, space } from '../theme';

export function HomeScreen() {
  const { go } = useAppState();

  return (
    <Screen
      eyebrow="Number duel"
      title="Guess the Number"
      subtitle="Think of a secret, or hunt for one. Six guesses against the computer — or an open-ended match against a friend."
    >
      <View style={styles.stack}>
        <ChoiceCard
          title="One player"
          description="Play against the computer. Decide who thinks of the number between 0 and 100."
          onPress={() => go('onePlayerRole')}
        />
        <ChoiceCard
          title="Two players"
          description="Same device, or find each other on the network with a room passcode."
          onPress={() => go('twoPlayerMode')}
        />
      </View>
      <Text style={styles.hint}>A sample from this repository’s JavaScript collection.</Text>
    </Screen>
  );
}

const styles = StyleSheet.create({
  stack: {
    gap: space.md,
  },
  hint: {
    marginTop: space.xl,
    color: colors.muted,
    fontSize: 13,
  },
});
