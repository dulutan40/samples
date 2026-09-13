import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { NumberPad, ValueDisplay } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { isInRange } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { colors, space } from '../theme';

export function SecretEntryScreen() {
  const { go, session, setSession } = useAppState();
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  if (!session) return null;

  const submit = () => {
    const secret = Number(value);
    if (!isInRange(secret, session.min, session.max)) {
      setError(`Enter a whole number from ${session.min} to ${session.max}.`);
      return;
    }
    setSession({ ...session, secret });
    setValue('');
    setError(null);
    go('playGuesser');
  };

  return (
    <Screen
      eyebrow="Keep it secret"
      title={`${session.thinkerName}, enter the number`}
      subtitle={`${session.guesserName}, look away until the guess screen appears.`}
      onBack={() => go('offlineSetup')}
      scroll={false}
    >
      <View style={styles.body}>
        <ValueDisplay value={value} placeholder={`${session.min} – ${session.max}`} />
        {error ? <Text style={styles.error}>{error}</Text> : null}
        <NumberPad
          value={value}
          onChange={(next) => {
            setValue(next);
            setError(null);
          }}
          onSubmit={submit}
          maxLength={String(session.max).length}
          submitLabel="Hide"
        />
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  body: {
    flex: 1,
    justifyContent: 'flex-end',
    paddingBottom: space.lg,
  },
  error: {
    color: colors.rose,
    marginBottom: space.md,
    textAlign: 'center',
  },
});
