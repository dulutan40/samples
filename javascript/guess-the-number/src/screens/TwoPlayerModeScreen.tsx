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
      subtitle="Share one phone, or sit on separate devices and meet in a room."
      onBack={() => go('home')}
    >
      <View style={styles.stack}>
        <ChoiceCard
          title="Offline"
          description="Same device. Choose a range, one player looks away while the other sets the secret, then guess without a limit."
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
