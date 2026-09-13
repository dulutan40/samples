import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { NumberPad, ValueDisplay } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { isInRange } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { submitSecret } from '../online/client';
import { colors, space } from '../theme';

export function OnlineSecretScreen() {
  const { goHome, session } = useAppState();
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  if (!session) return null;

  const submit = () => {
    const secret = Number(value);
    if (!isInRange(secret, session.min, session.max)) {
      setError(`Enter a whole number from ${session.min} to ${session.max}.`);
      return;
    }
    setError(null);
    setSent(true);
    submitSecret(secret);
  };

  return (
    <Screen
      eyebrow="Your secret"
      title="Think of a number"
      subtitle={`Pick a number from ${session.min} to ${session.max}. The other player will not see it.`}
      onBack={goHome}
      scroll={false}
    >
      <View style={styles.body}>
        {sent ? (
          <Text style={styles.sent}>Secret saved. Waiting for guesses…</Text>
        ) : (
          <>
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
              submitLabel="Lock in"
            />
          </>
        )}
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
  sent: {
    color: colors.gold,
    fontSize: 18,
    textAlign: 'center',
    marginBottom: space.xl,
  },
});
