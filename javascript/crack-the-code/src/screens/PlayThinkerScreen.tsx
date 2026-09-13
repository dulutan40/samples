import { useEffect, useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Button } from '../components/Button';
import { FeedbackLegend, FeedbackToggle, FeedbackView } from '../components/FeedbackView';
import { GuessHistory, GuessSlots } from '../components/GuessHistory';
import { Screen } from '../components/Screen';
import { isFeedbackPossible, isWon, nextComputerGuess, remainingGuesses } from '../game/engine';
import { useAppState } from '../navigation/AppState';
import { colors, radius, space } from '../theme';

export function PlayThinkerScreen() {
  const { go, goHome, session, setSession, feedbackMode, setFeedbackMode } = useAppState();
  const [plus, setPlus] = useState(0);
  const [minus, setMinus] = useState(0);
  const [thinking, setThinking] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  if (!session || session.computerGuess == null) return null;

  const used = session.guesses.length;
  const left = remainingGuesses(session.maxGuesses, used);

  const clampPair = (nextPlus: number, nextMinus: number) => {
    const p = Math.max(0, Math.min(session.length, nextPlus));
    const m = Math.max(0, Math.min(session.length - p, nextMinus));
    setPlus(p);
    setMinus(m);
    setError(null);
  };

  const respond = () => {
    if (thinking) return;
    if (!isFeedbackPossible(session.length, plus, minus)) {
      setError('Pluses and minuses cannot add up to more than the code length.');
      return;
    }

    const guesses = [...session.guesses, { value: session.computerGuess!, plus, minus }];

    if (isWon({ plus, minus }, session.length)) {
      setSession({ ...session, guesses, outcome: 'lost' });
      go('result');
      return;
    }

    const leftover = remainingGuesses(session.maxGuesses, guesses.length);
    if (leftover === 0) {
      setSession({ ...session, guesses, outcome: 'won' });
      go('result');
      return;
    }

    const nextGuess = nextComputerGuess(session.length, guesses);
    if (nextGuess == null) {
      setSession({ ...session, guesses, outcome: 'conflict' });
      go('result');
      return;
    }

    setThinking(true);
    setSession({ ...session, guesses });
    timerRef.current = setTimeout(() => {
      setSession({ ...session, guesses, computerGuess: nextGuess });
      setPlus(0);
      setMinus(0);
      setThinking(false);
    }, 650);
  };

  return (
    <Screen
      eyebrow="One player"
      title="Hold the code in your head"
      subtitle={`The computer is guessing a ${session.length}-digit code. Score the whole guess, not each slot.`}
      onBack={goHome}
      headerRight={<FeedbackToggle mode={feedbackMode} onChange={setFeedbackMode} />}
    >
      <View style={styles.meta}>
        {session.maxGuesses != null && left != null ? (
          <>
            <Text style={styles.metaLabel}>{left} guess{left === 1 ? '' : 'es'} left</Text>
            <GuessSlots total={session.maxGuesses} used={used} />
          </>
        ) : null}
        <FeedbackLegend mode={feedbackMode} />
      </View>

      <View style={styles.guessCard}>
        <Text style={styles.guessLabel}>{thinking ? 'Thinking…' : 'Computer guesses'}</Text>
        <Text style={styles.guessValue}>{thinking ? '—' : session.computerGuess}</Text>
      </View>

      <View style={styles.scoreBox}>
        <Stepper
          label="+"
          hint="Right place"
          value={plus}
          onChange={(next) => clampPair(next, minus)}
          disabled={thinking}
        />
        <Stepper
          label="−"
          hint="Wrong place"
          value={minus}
          onChange={(next) => clampPair(plus, next)}
          disabled={thinking}
        />
      </View>

      <View style={styles.preview}>
        <FeedbackView feedback={{ plus, minus }} length={session.length} mode={feedbackMode} />
      </View>

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <Button label="Send marks" onPress={respond} disabled={thinking} />

      <View style={styles.history}>
        <GuessHistory guesses={session.guesses} length={session.length} mode={feedbackMode} />
      </View>
    </Screen>
  );
}

function Stepper({
  label,
  hint,
  value,
  onChange,
  disabled,
}: {
  label: string;
  hint: string;
  value: number;
  onChange: (value: number) => void;
  disabled: boolean;
}) {
  return (
    <View style={styles.stepper}>
      <Text style={styles.stepLabel}>{label}</Text>
      <Text style={styles.stepHint}>{hint}</Text>
      <View style={styles.stepRow}>
        <Pressable
          onPress={() => onChange(value - 1)}
          disabled={disabled}
          style={[styles.stepBtn, disabled && styles.disabled]}
        >
          <Text style={styles.stepBtnLabel}>−</Text>
        </Pressable>
        <Text style={styles.stepValue}>{value}</Text>
        <Pressable
          onPress={() => onChange(value + 1)}
          disabled={disabled}
          style={[styles.stepBtn, disabled && styles.disabled]}
        >
          <Text style={styles.stepBtnLabel}>+</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  meta: {
    gap: space.sm,
    marginBottom: space.lg,
  },
  metaLabel: {
    color: colors.muted,
    fontSize: 15,
  },
  guessCard: {
    backgroundColor: colors.card,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.line,
    alignItems: 'center',
    paddingVertical: space.xl,
    marginBottom: space.lg,
  },
  guessLabel: {
    color: colors.accent,
    letterSpacing: 1.6,
    textTransform: 'uppercase',
    fontSize: 12,
    fontWeight: '700',
    marginBottom: space.sm,
  },
  guessValue: {
    color: colors.ink,
    fontSize: 48,
    fontWeight: '700',
    letterSpacing: 6,
    fontVariant: ['tabular-nums'],
  },
  scoreBox: {
    flexDirection: 'row',
    gap: space.md,
    marginBottom: space.md,
  },
  stepper: {
    flex: 1,
    backgroundColor: colors.card,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.line,
    padding: space.md,
  },
  stepLabel: {
    color: colors.ink,
    fontSize: 22,
    fontWeight: '700',
  },
  stepHint: {
    color: colors.muted,
    fontSize: 13,
    marginBottom: space.sm,
  },
  stepRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  stepBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.pad,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepBtnLabel: {
    color: colors.ink,
    fontSize: 20,
    fontWeight: '700',
  },
  stepValue: {
    color: colors.ink,
    fontSize: 24,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  preview: {
    alignItems: 'center',
    marginBottom: space.md,
  },
  error: {
    color: colors.miss,
    marginBottom: space.md,
    textAlign: 'center',
  },
  history: {
    marginTop: space.lg,
  },
  disabled: {
    opacity: 0.4,
  },
});
