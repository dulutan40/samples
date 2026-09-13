import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AppStateProvider, useAppState } from './src/navigation/AppState';
import { useOnlineBridge } from './src/online/useOnlineBridge';
import { CreateRoomScreen } from './src/screens/CreateRoomScreen';
import { HomeScreen } from './src/screens/HomeScreen';
import { JoinRoomScreen } from './src/screens/JoinRoomScreen';
import { OfflineSetupScreen } from './src/screens/OfflineSetupScreen';
import { OnePlayerRoleScreen } from './src/screens/OnePlayerRoleScreen';
import { OnlineMenuScreen } from './src/screens/OnlineMenuScreen';
import { OnlinePlayScreen } from './src/screens/OnlinePlayScreen';
import { OnlineResultScreen } from './src/screens/OnlineResultScreen';
import { OnlineSecretScreen } from './src/screens/OnlineSecretScreen';
import { OnlineSetupScreen } from './src/screens/OnlineSetupScreen';
import { PlayGuesserScreen } from './src/screens/PlayGuesserScreen';
import { PlayThinkerScreen } from './src/screens/PlayThinkerScreen';
import { ResultScreen } from './src/screens/ResultScreen';
import { SecretEntryScreen } from './src/screens/SecretEntryScreen';
import { TwoPlayerModeScreen } from './src/screens/TwoPlayerModeScreen';

function AppShell() {
  useOnlineBridge();
  const { screen } = useAppState();

  switch (screen) {
    case 'home':
      return <HomeScreen />;
    case 'onePlayerRole':
      return <OnePlayerRoleScreen />;
    case 'twoPlayerMode':
      return <TwoPlayerModeScreen />;
    case 'offlineSetup':
      return <OfflineSetupScreen />;
    case 'secretEntry':
      return <SecretEntryScreen />;
    case 'playGuesser':
      return <PlayGuesserScreen />;
    case 'playThinker':
      return <PlayThinkerScreen />;
    case 'result':
      return <ResultScreen />;
    case 'onlineMenu':
      return <OnlineMenuScreen />;
    case 'createRoom':
      return <CreateRoomScreen />;
    case 'joinRoom':
      return <JoinRoomScreen />;
    case 'onlineSetup':
      return <OnlineSetupScreen />;
    case 'onlineSecret':
      return <OnlineSecretScreen />;
    case 'onlinePlay':
      return <OnlinePlayScreen />;
    case 'onlineResult':
      return <OnlineResultScreen />;
    default:
      return <HomeScreen />;
  }
}

export default function App() {
  return (
    <SafeAreaProvider>
      <AppStateProvider>
        <AppShell />
      </AppStateProvider>
    </SafeAreaProvider>
  );
}
