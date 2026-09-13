import { useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { ChoiceCard } from '../components/ChoiceCard';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { disconnectFromServer, setupGame } from '../online/client';
import { TWO_PLAYER_RANGES, type RangeOption } from '../types';
import { colors, radius, space } from '../theme';

export function OnlineSetupScreen() {
  const { go, online, setOnline } = useAppState();
  const [range, setRange] = useState<RangeOption>(TWO_PLAYER_RANGES[0]);
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
        subtitle="The host is choosing the range and who thinks of the number."
        onBack={leave}
      >
        <View style={styles.waiting}>
          <ActivityIndicator color={colors.gold} />
          <Text style={styles.waitingText}>Waiting for the host…</Text>
        </View>
      </Screen>
    );
  }

  return (
    <Screen
      eyebrow={`Room ${online.passcode ?? ''}`}
      title="Set up the match"
      subtitle="The room is locked. Choose a range and whether you think of the number or guess."
      onBack={leave}
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
          description="The other player thinks of a number. You guess with no limit."
          selected={!hostThinks}
          onPress={() => setHostThinks(false)}
        />
      </View>

      {online.error ? <Text style={styles.error}>{online.error}</Text> : null}

      <View style={styles.cta}>
        <Button label="Start" onPress={() => setupGame(range.min, range.max, hostThinks)} />
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
  error: {
    color: colors.rose,
    marginTop: space.md,
  },
  cta: {
    marginTop: space.xl,
  },
});
