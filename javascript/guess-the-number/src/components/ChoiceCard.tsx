import { Pressable, StyleSheet, Text, View } from 'react-native';
import { colors, radius, space } from '../theme';

type Props = {
  title: string;
  description: string;
  onPress: () => void;
  selected?: boolean;
};

export function ChoiceCard({ title, description, onPress, selected = false }: Props) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.card,
        selected && styles.selected,
        pressed && styles.pressed,
      ]}
    >
      <View style={styles.copy}>
        <Text style={styles.title}>{title}</Text>
        <Text style={styles.description}>{description}</Text>
      </View>
      <Text style={styles.chevron}>→</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.card,
    borderRadius: radius.lg,
    padding: space.lg,
    borderWidth: 1,
    borderColor: colors.line,
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.md,
  },
  selected: {
    borderColor: colors.gold,
    backgroundColor: colors.cardHover,
  },
  pressed: {
    backgroundColor: colors.cardHover,
  },
  copy: {
    flex: 1,
    gap: 6,
  },
  title: {
    color: colors.ink,
    fontSize: 18,
    fontWeight: '700',
  },
  description: {
    color: colors.muted,
    fontSize: 15,
    lineHeight: 22,
  },
  chevron: {
    color: colors.gold,
    fontSize: 20,
    fontWeight: '600',
  },
});
