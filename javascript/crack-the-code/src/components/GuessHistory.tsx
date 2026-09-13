import { ScrollView, StyleSheet, Text, View } from 'react-native';
import type { FeedbackMode, Guess } from '../types';
import { colors, radius, space } from '../theme';
import { FeedbackView } from './FeedbackView';

export function GuessHistory({
  guesses,
  length,
  mode,
}: {
  guesses: Guess[];
  length: number;
  mode: FeedbackMode;
}) {
  if (guesses.length === 0) {
    return <Text style={styles.empty}>No guesses yet.</Text>;
  }

  return (
    <ScrollView style={styles.list} contentContainerStyle={styles.content}>
      {guesses.map((guess, index) => (
        <View key={`${guess.value}-${index}`} style={styles.row}>
          <Text style={styles.index}>{index + 1}</Text>
          <Text style={styles.value}>{guess.value}</Text>
          <FeedbackView feedback={guess} length={length} mode={mode} />
        </View>
      ))}
    </ScrollView>
  );
}

export function GuessSlots({ total, used }: { total: number; used: number }) {
  return (
    <View style={styles.slots}>
      {Array.from({ length: total }, (_, index) => (
        <View key={index} style={[styles.slot, index < used ? styles.slotUsed : styles.slotOpen]} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  list: {
    maxHeight: 200,
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
    fontSize: 20,
    fontWeight: '700',
    letterSpacing: 2,
    fontVariant: ['tabular-nums'],
    minWidth: 88,
  },
  slots: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  slot: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  slotOpen: {
    backgroundColor: colors.line,
  },
  slotUsed: {
    backgroundColor: colors.accent,
  },
});
