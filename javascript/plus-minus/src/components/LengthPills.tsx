import { Pressable, StyleSheet, Text, View } from 'react-native';
import { DIGIT_LENGTHS, type DigitLength } from '../types';
import { colors, radius, space } from '../theme';

export function LengthPills({
  value,
  onChange,
}: {
  value: DigitLength;
  onChange: (length: DigitLength) => void;
}) {
  return (
    <View style={styles.row}>
      {DIGIT_LENGTHS.map((length) => {
        const selected = length === value;
        return (
          <Pressable
            key={length}
            onPress={() => onChange(length)}
            style={[styles.pill, selected && styles.pillOn]}
          >
            <Text style={[styles.label, selected && styles.labelOn]}>{length} digits</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: space.sm,
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
    backgroundColor: colors.accent,
    borderColor: colors.accent,
  },
  label: {
    color: colors.ink,
    fontWeight: '700',
  },
  labelOn: {
    color: colors.bg,
  },
});
