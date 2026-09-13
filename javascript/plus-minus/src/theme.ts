export const colors = {
  bg: '#120E14',
  bgElevated: '#1B151F',
  card: '#231B28',
  cardHover: '#2C2233',
  line: '#3A2E44',
  ink: '#F4EFE6',
  muted: '#A396AB',
  accent: '#C9A6E0',
  plus: '#2ECC71',
  minus: '#F1C40F',
  miss: '#E74C3C',
  pad: '#2A2131',
};

export const space = {
  xs: 6,
  sm: 10,
  md: 16,
  lg: 24,
  xl: 36,
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
  },
};
