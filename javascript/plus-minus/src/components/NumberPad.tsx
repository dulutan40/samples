import { Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, radius, space } from '../theme';

const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'back', '0', 'ok'] as const;

type Props = {
  value: string;
  onChange: (value: string) => void;
  onSubmit: () => void;
  length: number;
  submitLabel?: string;
  disabled?: boolean;
  uniqueDigits?: boolean;
};

export function NumberPad({
  value,
  onChange,
  onSubmit,
  length,
  submitLabel = 'OK',
  disabled = false,
  uniqueDigits = true,
}: Props) {
  const used = new Set(value.split(''));

  const press = (key: (typeof KEYS)[number]) => {
    if (disabled) return;
    if (key === 'back') {
      onChange(value.slice(0, -1));
      return;
    }
    if (key === 'ok') {
      onSubmit();
      return;
    }
    if (value.length >= length || (uniqueDigits && used.has(key))) return;
    onChange(value + key);
  };

  return (
    <View style={styles.grid}>
      {KEYS.map((key) => {
        const label = key === 'back' ? '⌫' : key === 'ok' ? submitLabel : key;
        const taken = uniqueDigits && key !== 'back' && key !== 'ok' && used.has(key);
        const submitBlocked = key === 'ok' && value.length !== length;
        const blocked = disabled || taken || submitBlocked;
        return (
          <Pressable
            key={key}
            onPress={() => press(key)}
            disabled={blocked && key !== 'back'}
            style={({ pressed }) => [
              styles.key,
              (key === 'back' || key === 'ok') && styles.action,
              key === 'ok' && styles.ok,
              pressed && !blocked && styles.pressed,
              (blocked && key !== 'back') && styles.disabled,
            ]}
          >
            <Text style={[styles.label, key === 'ok' && styles.okLabel]}>{label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export function CodeDisplay({ value, length, placeholder }: { value: string; length: number; placeholder?: string }) {
  return (
    <View style={styles.slots}>
      {Array.from({ length }, (_, index) => (
        <View key={index} style={styles.slot}>
          <Text style={[styles.slotText, !value[index] && styles.slotEmpty]}>
            {value[index] ?? (placeholder && index === 0 ? '' : '·')}
          </Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: space.sm,
  },
  key: {
    width: '31%',
    flexGrow: 1,
    minHeight: 62,
    borderRadius: radius.md,
    backgroundColor: colors.pad,
    alignItems: 'center',
    justifyContent: 'center',
  },
  action: {
    backgroundColor: colors.bgElevated,
  },
  ok: {
    backgroundColor: colors.accent,
  },
  pressed: {
    opacity: 0.8,
  },
  disabled: {
    opacity: 0.35,
  },
  label: {
    color: colors.ink,
    fontSize: 22,
    fontWeight: '700',
  },
  okLabel: {
    color: colors.bg,
    fontSize: 16,
  },
  slots: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: space.sm,
    marginBottom: space.lg,
  },
  slot: {
    width: 52,
    height: 64,
    borderRadius: radius.md,
    backgroundColor: colors.bgElevated,
    borderWidth: 1,
    borderColor: colors.line,
    alignItems: 'center',
    justifyContent: 'center',
  },
  slotText: {
    color: colors.ink,
    fontSize: 28,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  slotEmpty: {
    color: colors.muted,
  },
});
