import { useEffect } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { Screen } from '../components/Screen';
import { useAppState } from '../navigation/AppState';
import { connectToServer, createRoom, disconnectFromServer } from '../online/client';
import { colors, radius, space } from '../theme';

export function CreateRoomScreen() {
  const { go, online, setOnline } = useAppState();

  useEffect(() => {
    setOnline((current) => ({ ...current, phase: 'connecting', error: null, passcode: null }));
    const socket = connectToServer(online.serverUrl);
    const start = () => createRoom();
    if (socket.connected) {
      start();
    } else {
      socket.on('connect', start);
    }
    return () => {
      socket.off('connect', start);
    };
  }, [online.serverUrl, setOnline]);

  const leave = () => {
    disconnectFromServer();
    setOnline((current) => ({
      ...current,
      phase: 'idle',
      passcode: null,
      playerCount: 0,
      isHost: false,
      error: null,
    }));
    go('onlineMenu');
  };

  return (
    <Screen
      eyebrow="Host"
      title="Your room"
      subtitle="Share this passcode. The room locks as soon as the second player joins."
      onBack={leave}
    >
      <View style={styles.passcodeCard}>
        {online.passcode ? (
          <Text style={styles.passcode}>{online.passcode}</Text>
        ) : (
          <ActivityIndicator color={colors.accent} />
        )}
        <Text style={styles.passcodeHint}>
          {online.passcode ? 'Room passcode' : 'Opening a room…'}
        </Text>
      </View>

      <View style={styles.status}>
        <ActivityIndicator color={colors.accent} />
        <Text style={styles.statusText}>Waiting for the other player to join…</Text>
      </View>

      {online.error ? <Text style={styles.error}>{online.error}</Text> : null}

      <Button label="Cancel" variant="secondary" onPress={leave} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  passcodeCard: {
    backgroundColor: colors.card,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.line,
    minHeight: 160,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: space.xl,
  },
  passcode: {
    color: colors.accent,
    fontSize: 56,
    fontWeight: '700',
    letterSpacing: 10,
    fontVariant: ['tabular-nums'],
  },
  passcodeHint: {
    color: colors.muted,
    marginTop: space.sm,
  },
  status: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: space.md,
    marginBottom: space.xl,
  },
  statusText: {
    color: colors.ink,
    flex: 1,
    fontSize: 16,
  },
  error: {
    color: colors.miss,
    marginBottom: space.md,
  },
});
