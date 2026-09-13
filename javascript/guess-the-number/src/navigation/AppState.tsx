import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';
import {
  DEFAULT_SERVER_URL,
  type OnlineState,
  type ScreenName,
  type Session,
} from '../types';
import { disconnectFromServer } from '../online/client';

type AppStateValue = {
  screen: ScreenName;
  session: Session | null;
  online: OnlineState;
  go: (screen: ScreenName) => void;
  setSession: (session: Session | null | ((current: Session | null) => Session | null)) => void;
  setOnline: (online: OnlineState | ((current: OnlineState) => OnlineState)) => void;
  goHome: () => void;
};

const AppStateContext = createContext<AppStateValue | null>(null);

const initialOnline = (): OnlineState => ({
  serverUrl: DEFAULT_SERVER_URL,
  passcode: null,
  isHost: false,
  phase: 'idle',
  error: null,
  playerCount: 0,
});

export function AppStateProvider({ children }: { children: ReactNode }) {
  const [screen, setScreen] = useState<ScreenName>('home');
  const [session, setSession] = useState<Session | null>(null);
  const [online, setOnline] = useState<OnlineState>(initialOnline);

  const value = useMemo<AppStateValue>(
    () => ({
      screen,
      session,
      online,
      go: setScreen,
      setSession,
      setOnline,
      goHome: () => {
        disconnectFromServer();
        setSession(null);
        setOnline((current) => ({
          ...initialOnline(),
          serverUrl: current.serverUrl,
        }));
        setScreen('home');
      },
    }),
    [screen, session, online],
  );

  return <AppStateContext.Provider value={value}>{children}</AppStateContext.Provider>;
}

export function useAppState() {
  const value = useContext(AppStateContext);
  if (!value) {
    throw new Error('useAppState must be used inside AppStateProvider');
  }
  return value;
}
