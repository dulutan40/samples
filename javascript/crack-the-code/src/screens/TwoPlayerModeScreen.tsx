import { StyleSheet, View } from 'react-native';
import { ChoiceCard } from '../components/ChoiceCard';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { space } from '../theme';

export function TwoPlayerModeScreen() {
  const { go } = useAppState();

  return (
    <Screen
      eyebrow="Two players"
      title="How will you play?"
      subtitle="Share one device, or sit apart and meet with a room passcode."
      onBack={() => go('home')}
    >
      <View style={styles.stack}>
        <ChoiceCard
          title="Offline"
          description="Same device. One player looks away while the other sets the code. No guess limit."
          onPress={() => go('offlineSetup')}
        />
        <ChoiceCard
          title="Online"
          description="Create a room with a passcode or join one. The room locks when the second player arrives."
          onPress={() => go('onlineMenu')}
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
