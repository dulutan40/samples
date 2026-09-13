import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { CodeDisplay, NumberPad } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { isValidCode } from '../game/engine';
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
    if (!isValidCode(value, session.length)) {
      setError(`Enter ${session.length} different digits.`);
      return;
    }
    setError(null);
    setSent(true);
    submitSecret(value);
  };

  return (
    <Screen
      eyebrow="Your secret"
      title="Think of a number"
      subtitle={`Pick ${session.length} unique digits. The other player will not see them. Zero can be first.`}
      onBack={goHome}
      scroll={false}
    >
      <View style={styles.body}>
        {sent ? (
          <Text style={styles.sent}>Secret saved. Waiting for guesses…</Text>
        ) : (
          <>
            <CodeDisplay value={value} length={session.length} />
            {error ? <Text style={styles.error}>{error}</Text> : null}
            <NumberPad
              value={value}
              onChange={(next) => {
                setValue(next);
                setError(null);
              }}
              onSubmit={submit}
              length={session.length}
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
    color: colors.miss,
    marginBottom: space.md,
    textAlign: 'center',
  },
  sent: {
    color: colors.accent,
    fontSize: 18,
    textAlign: 'center',
    marginBottom: space.xl,
  },
});
