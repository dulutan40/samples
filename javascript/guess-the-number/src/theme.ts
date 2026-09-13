export const colors = {
  bg: '#0B1020',
  bgElevated: '#121A2E',
  card: '#18233A',
  cardHover: '#1E2C48',
  line: '#2A3654',
  gold: '#E8B84A',
  goldMuted: '#9A7A2E',
  ink: '#F6F1E6',
  muted: '#8E97AD',
  blue: '#5B93FF',
  teal: '#3DDC97',
  rose: '#FF6B7A',
  pad: '#1E2A44',
  overlay: 'rgba(6, 10, 20, 0.72)',
};

export const space = {
  xs: 6,
  sm: 10,
  md: 16,
  lg: 24,
  xl: 36,
  xxl: 48,
};

export const radius = {
  sm: 10,
  md: 16,
  lg: 22,
  pill: 999,
};

export const type = {
  overline: {
    fontSize: 12,
    letterSpacing: 2.2,
    fontWeight: '600' as const,
    textTransform: 'uppercase' as const,
  },
  title: {
    fontSize: 34,
    lineHeight: 40,
    fontWeight: '700' as const,
    letterSpacing: -0.6,
  },
  subtitle: {
    fontSize: 16,
    lineHeight: 24,
    fontWeight: '400' as const,
  },
  body: {
    fontSize: 16,
    lineHeight: 24,
  },
  number: {
    fontSize: 56,
    lineHeight: 62,
    fontWeight: '700' as const,
    letterSpacing: -1.4,
    fontVariant: ['tabular-nums'] as const,
  },
};
