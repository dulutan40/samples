import { Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, radius, space } from '../theme';

const KEYS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'back', '0', 'ok'] as const;

type Props = {
  value: string;
  onChange: (value: string) => void;
  onSubmit: () => void;
  maxLength?: number;
  submitLabel?: string;
  disabled?: boolean;
};

export function NumberPad({
  value,
  onChange,
  onSubmit,
  maxLength = 5,
  submitLabel = 'OK',
  disabled = false,
}: Props) {
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
    if (value.length >= maxLength) return;
    onChange(value + key);
  };

  return (
    <View style={styles.grid}>
      {KEYS.map((key) => {
        const label = key === 'back' ? '⌫' : key === 'ok' ? submitLabel : key;
        const isAction = key === 'back' || key === 'ok';
        return (
          <Pressable
            key={key}
            onPress={() => press(key)}
            disabled={disabled || (key === 'ok' && value.length === 0)}
            style={({ pressed }) => [
              styles.key,
              isAction && styles.action,
              key === 'ok' && styles.ok,
              pressed && styles.pressed,
              (disabled || (key === 'ok' && value.length === 0)) && styles.disabled,
            ]}
          >
            <Text style={[styles.label, key === 'ok' && styles.okLabel]}>{label}</Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export function ValueDisplay({ value, placeholder }: { value: string; placeholder: string }) {
  return (
    <View style={styles.display}>
      <Text style={[styles.displayText, !value && styles.placeholder]}>
        {value || placeholder}
      </Text>
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
    backgroundColor: colors.gold,
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
  display: {
    minHeight: 88,
    borderRadius: radius.lg,
    backgroundColor: colors.bgElevated,
    borderWidth: 1,
    borderColor: colors.line,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: space.lg,
  },
  displayText: {
    color: colors.ink,
    fontSize: 48,
    fontWeight: '700',
    letterSpacing: -1,
    fontVariant: ['tabular-nums'],
  },
  placeholder: {
    color: colors.muted,
    fontSize: 22,
    fontWeight: '600',
    letterSpacing: 0,
  },
});
