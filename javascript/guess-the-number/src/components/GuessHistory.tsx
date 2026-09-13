import { ScrollView, StyleSheet, Text, View } from 'react-native';
import type { Guess } from '../types';
import { colors, radius, space } from '../theme';

function hint(result: Guess['result']) {
  if (result === 'correct') return { mark: '=', label: 'Correct', color: colors.teal };
  if (result === 'lower') return { mark: '↑', label: 'Too low', color: colors.blue };
  return { mark: '↓', label: 'Too high', color: colors.rose };
}

export function GuessHistory({ guesses }: { guesses: Guess[] }) {
  if (guesses.length === 0) {
    return <Text style={styles.empty}>No guesses yet.</Text>;
  }

  return (
    <ScrollView style={styles.list} contentContainerStyle={styles.content}>
      {guesses.map((guess, index) => {
        const copy = hint(guess.result);
        return (
          <View key={`${guess.value}-${index}`} style={styles.row}>
            <Text style={styles.index}>{index + 1}</Text>
            <Text style={styles.value}>{guess.value}</Text>
            <View style={[styles.badge, { backgroundColor: copy.color }]}>
              <Text style={styles.badgeText}>
                {copy.mark}  {copy.label}
              </Text>
            </View>
          </View>
        );
      })}
    </ScrollView>
  );
}

export function GuessSlots({ total, used }: { total: number; used: number }) {
  return (
    <View style={styles.slots}>
      {Array.from({ length: total }, (_, index) => (
        <View
          key={index}
          style={[styles.slot, index < used ? styles.slotUsed : styles.slotOpen]}
        />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  list: {
    maxHeight: 180,
  },
  content: {
    gap: space.sm,
  },
  empty: {
    color: colors.muted,
    fontSize: 15,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.md,
    backgroundColor: colors.card,
    borderRadius: radius.sm,
    paddingVertical: 10,
    paddingHorizontal: space.md,
  },
  index: {
    color: colors.muted,
    width: 18,
    fontVariant: ['tabular-nums'],
  },
  value: {
    color: colors.ink,
    fontSize: 18,
    fontWeight: '700',
    width: 72,
    fontVariant: ['tabular-nums'],
  },
  badge: {
    marginLeft: 'auto',
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  badgeText: {
    color: colors.bg,
    fontSize: 12,
    fontWeight: '700',
  },
  slots: {
    flexDirection: 'row',
    gap: 8,
  },
  slot: {
    width: 14,
    height: 14,
    borderRadius: 7,
  },
  slotOpen: {
    backgroundColor: colors.line,
  },
  slotUsed: {
    backgroundColor: colors.gold,
  },
});
