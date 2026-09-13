import { Pressable, StyleSheet, Text, View } from 'react-native';
import { formatNumeric, missCount } from '../game/engine';
import type { Feedback, FeedbackMode } from '../types';
import { colors, radius, space } from '../theme';

type Props = {
  feedback: Feedback;
  length: number;
  mode: FeedbackMode;
};

export function FeedbackView({ feedback, length, mode }: Props) {
  if (mode === 'numeric') {
    return <Text style={styles.numeric}>{formatNumeric(feedback)}</Text>;
  }

  const reds = missCount(feedback, length);
  const pips = [
    ...Array.from({ length: feedback.plus }, () => colors.plus),
    ...Array.from({ length: feedback.minus }, () => colors.minus),
    ...Array.from({ length: reds }, () => colors.miss),
  ];

  return (
    <View style={styles.pips} accessibilityLabel={formatNumeric(feedback)}>
      {pips.map((color, index) => (
        <View key={`${color}-${index}`} style={[styles.pip, { backgroundColor: color }]} />
      ))}
    </View>
  );
}

export function FeedbackToggle({
  mode,
  onChange,
}: {
  mode: FeedbackMode;
  onChange: (mode: FeedbackMode) => void;
}) {
  return (
    <View style={styles.toggle}>
      <Pressable
        onPress={() => onChange('numeric')}
        style={[styles.toggleBtn, mode === 'numeric' && styles.toggleOn]}
      >
        <Text style={[styles.toggleLabel, mode === 'numeric' && styles.toggleLabelOn]}>+ −</Text>
      </Pressable>
      <Pressable
        onPress={() => onChange('color')}
        style={[styles.toggleBtn, mode === 'color' && styles.toggleOn]}
      >
        <Text style={[styles.toggleLabel, mode === 'color' && styles.toggleLabelOn]}>Colors</Text>
      </Pressable>
    </View>
  );
}

export function FeedbackLegend({ mode }: { mode: FeedbackMode }) {
  if (mode === 'numeric') {
    return (
      <Text style={styles.legend}>
        + is a digit in the right place. − is a digit that belongs, but not there. The marks are for
        the whole guess, not each slot.
      </Text>
    );
  }
  return (
    <View style={styles.legendRow}>
      <LegendSwatch color={colors.plus} label="Right place" />
      <LegendSwatch color={colors.minus} label="Wrong place" />
      <LegendSwatch color={colors.miss} label="Not in the number" />
    </View>
  );
}

function LegendSwatch({ color, label }: { color: string; label: string }) {
  return (
    <View style={styles.swatch}>
      <View style={[styles.pip, { backgroundColor: color }]} />
      <Text style={styles.legend}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  numeric: {
    color: colors.ink,
    fontSize: 16,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  pips: {
    flexDirection: 'row',
    gap: 6,
  },
  pip: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  toggle: {
    flexDirection: 'row',
    backgroundColor: colors.card,
    borderRadius: radius.pill,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 3,
  },
  toggleBtn: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: radius.pill,
  },
  toggleOn: {
    backgroundColor: colors.accent,
  },
  toggleLabel: {
    color: colors.muted,
    fontSize: 13,
    fontWeight: '700',
  },
  toggleLabelOn: {
    color: colors.bg,
  },
  legend: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 18,
  },
  legendRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: space.md,
  },
  swatch: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
});
