import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { CodeDisplay, NumberPad } from '../components/NumberPad';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { connectToServer, disconnectFromServer, joinRoom } from '../online/client';
import { colors, space } from '../theme';

export function JoinRoomScreen() {
  const { go, online, setOnline } = useAppState();
  const [value, setValue] = useState('');

  const leave = () => {
    disconnectFromServer();
    setOnline((current) => ({
      ...current,
      phase: 'idle',
      passcode: null,
      playerCount: 0,
      isHost: false,
    }));
    go('onlineMenu');
  };

  const submit = () => {
    if (value.length !== 4) {
      setOnline((current) => ({ ...current, error: 'Enter the 4-digit passcode.' }));
      return;
    }
    setOnline((current) => ({ ...current, phase: 'connecting', error: null }));
    const socket = connectToServer(online.serverUrl);
    const start = () => joinRoom(value);
    if (socket.connected) {
      start();
    } else {
      socket.once('connect', start);
    }
  };

  return (
    <Screen
      eyebrow="Join"
      title="Enter the passcode"
      subtitle="Ask the host for the four-digit code. You cannot join a room that already has two players."
      onBack={leave}
      scroll={false}
    >
      <View style={styles.body}>
        <CodeDisplay value={value} length={4} />
        {online.error ? <Text style={styles.error}>{online.error}</Text> : null}
        <NumberPad
          value={value}
          onChange={(next) => {
            setValue(next);
            if (online.error) {
              setOnline((current) => ({ ...current, error: null }));
            }
          }}
          onSubmit={submit}
          length={4}
          submitLabel="Join"
          uniqueDigits={false}
          disabled={online.phase === 'connecting'}
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
