import { StyleSheet, Text, TextInput, View } from 'react-native';
import { ChoiceCard } from '../components/ChoiceCard';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { colors, radius, space } from '../theme';

export function OnlineMenuScreen() {
  const { go, online, setOnline } = useAppState();

  return (
    <Screen
      eyebrow="Online"
      title="Find each other"
      subtitle="One player creates a room and shares the passcode. The other joins. The room locks at two players."
      onBack={() => go('twoPlayerMode')}
    >
      <Text style={styles.section}>Room server</Text>
      <TextInput
        value={online.serverUrl}
        onChangeText={(serverUrl) => setOnline((current) => ({ ...current, serverUrl, error: null }))}
        autoCapitalize="none"
        autoCorrect={false}
        placeholder="http://192.168.1.10:3456"
        placeholderTextColor={colors.muted}
        style={styles.input}
      />
      <Text style={styles.help}>
        On this computer use localhost. On a phone, use the computer’s Wi-Fi address and keep the
        room server running.
      </Text>

      {online.error ? <Text style={styles.error}>{online.error}</Text> : null}

      <View style={styles.stack}>
        <ChoiceCard
          title="Create a room"
          description="You get a passcode. Wait for the other player to join, then set the range and roles."
          onPress={() => go('createRoom')}
        />
        <ChoiceCard
          title="Join a room"
          description="Enter the passcode from the host. You cannot join a locked room."
          onPress={() => go('joinRoom')}
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
  input: {
    backgroundColor: colors.bgElevated,
    borderWidth: 1,
    borderColor: colors.line,
    borderRadius: radius.md,
    color: colors.ink,
    paddingHorizontal: space.md,
    paddingVertical: 14,
    fontSize: 16,
  },
  help: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 20,
    marginTop: space.sm,
    marginBottom: space.lg,
  },
  error: {
    color: colors.rose,
    marginBottom: space.md,
  },
  stack: {
    gap: space.md,
  },
});
