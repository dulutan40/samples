import { useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { ChoiceCard } from '../components/ChoiceCard';
import { LengthPills } from '../components/LengthPills';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { disconnectFromServer, setupGame } from '../online/client';
import { colors, space } from '../theme';

export function OnlineSetupScreen() {
  const { go, online, setOnline, digitLength, setDigitLength } = useAppState();
  const [hostThinks, setHostThinks] = useState(true);

  const leave = () => {
    disconnectFromServer();
    setOnline((current) => ({
      ...current,
      phase: 'idle',
      passcode: null,
      playerCount: 0,
      isHost: false,
      error: null,
    }));
    go('onlineMenu');
  };

  if (!online.isHost) {
    return (
      <Screen
        eyebrow={`Room ${online.passcode ?? ''}`}
        title="Room is locked"
        subtitle="The host is choosing the code length and who thinks of the number."
        onBack={leave}
      >
        <View style={styles.waiting}>
          <ActivityIndicator color={colors.accent} />
          <Text style={styles.waitingText}>Waiting for the host…</Text>
        </View>
      </Screen>
    );
  }

  return (
    <Screen
      eyebrow={`Room ${online.passcode ?? ''}`}
      title="Set up the match"
      subtitle="The room is locked. Choose a length and whether you think of the code or guess."
      onBack={leave}
    >
      <Text style={styles.section}>Code length</Text>
      <LengthPills value={digitLength} onChange={setDigitLength} />

      <Text style={styles.section}>Your role</Text>
      <View style={styles.stack}>
        <ChoiceCard
          title="I will think of the number"
          description="You enter a secret on your device. The other player guesses with no limit."
          selected={hostThinks}
          onPress={() => setHostThinks(true)}
        />
        <ChoiceCard
          title="I will guess"
          description="The other player thinks of a code. You guess with no limit."
          selected={!hostThinks}
          onPress={() => setHostThinks(false)}
        />
      </View>

      {online.error ? <Text style={styles.error}>{online.error}</Text> : null}

      <View style={styles.cta}>
        <Button label="Start" onPress={() => setupGame(digitLength, hostThinks)} />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  waiting: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.md,
    marginTop: space.lg,
  },
  waitingText: {
    color: colors.ink,
    fontSize: 16,
  },
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
  error: {
    color: colors.miss,
    marginTop: space.md,
  },
  cta: {
    marginTop: space.xl,
  },
});
