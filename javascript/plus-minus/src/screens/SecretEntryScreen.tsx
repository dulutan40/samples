import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { CodeDisplay, NumberPad } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { isValidCode } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { colors, space } from '../theme';

export function SecretEntryScreen() {
  const { go, session, setSession } = useAppState();
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  if (!session) return null;

  const submit = () => {
    if (!isValidCode(value, session.length)) {
      setError(`Enter ${session.length} different digits.`);
      return;
    }
    setSession({ ...session, secret: value });
    setValue('');
    setError(null);
    go('playGuesser');
  };

  return (
    <Screen
      eyebrow="Keep it secret"
      title={`${session.thinkerName}, enter the code`}
      subtitle={`${session.guesserName}, look away. Digits cannot repeat. Zero can be first.`}
      onBack={() => go('offlineSetup')}
      scroll={false}
    >
      <View style={styles.body}>
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
    color: colors.miss,
    marginBottom: space.md,
    textAlign: 'center',
  },
});
