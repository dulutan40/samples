import { type ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { colors, space, type } from '../theme';

type Props = {
  children: ReactNode;
  title?: string;
  eyebrow?: string;
  subtitle?: string;
  onBack?: () => void;
  scroll?: boolean;
  headerRight?: ReactNode;
};

export function Screen({
  children,
  title,
  eyebrow,
  subtitle,
  onBack,
  scroll = true,
  headerRight,
}: Props) {
  const header = (
    <View style={styles.header}>
      <View style={styles.topRow}>
        {onBack ? (
          <Pressable onPress={onBack} hitSlop={12} style={styles.back}>
            <Text style={styles.backLabel}>Back</Text>
          </Pressable>
        ) : (
          <View style={styles.backSpacer} />
        )}
        {headerRight}
      </View>
      {eyebrow ? <Text style={styles.eyebrow}>{eyebrow}</Text> : null}
      {title ? <Text style={styles.title}>{title}</Text> : null}
      {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
    </View>
  );

  return (
    <SafeAreaView style={styles.safe} edges={['top', 'bottom', 'left', 'right']}>
      <StatusBar style="light" />
      {scroll ? (
        <ScrollView
          contentContainerStyle={styles.scroll}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {header}
          {children}
        </ScrollView>
      ) : (
        <View style={styles.body}>
          {header}
          <View style={styles.fill}>{children}</View>
        </View>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  scroll: {
    paddingHorizontal: space.lg,
    paddingBottom: space.xl,
  },
  body: {
    flex: 1,
    paddingHorizontal: space.lg,
  },
  fill: {
    flex: 1,
  },
  header: {
    paddingTop: space.sm,
    paddingBottom: space.lg,
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    minHeight: 28,
    marginBottom: space.sm,
  },
  back: {
    paddingVertical: 4,
  },
  backSpacer: {
    height: 8,
  },
  backLabel: {
    color: colors.accent,
    fontSize: 16,
    fontWeight: '600',
  },
  eyebrow: {
    ...type.overline,
    color: colors.accent,
    marginBottom: space.sm,
  },
  title: {
    ...type.title,
    color: colors.ink,
  },
  subtitle: {
    ...type.subtitle,
    color: colors.muted,
    marginTop: space.sm,
  },
});
