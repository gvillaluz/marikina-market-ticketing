
export const theme = {
  colors: {
  
    primary: '#0B2D5B',

    primaryHover: '#0A2650',

    accent: '#B8792F',

    accentHover: '#A66A24',

    bgPage: '#EEF2F8',

    bgCard: '#E9F0F8',

    bgSurface: '#FFFFFF',

    borderDefault: '#D9E1EC',

    textHeading: '#0B2D5B',

    textBody: '#5B6472',

    textMuted: '#94A0B2',

    textOnPrimary: '#FFFFFF',

    statusHigh: '#C0392B',
    statusMedium: '#B8792F',
    statusLow: '#4C8B5A',
  },
  spacing: {
    xs: '0.25rem',
    sm: '0.5rem',
    md: '1rem',
    lg: '1.5rem',
    xl: '2rem',
    xxl: '3rem',
  },
  radius: {
    sm: '6px',
    md: '10px',
    lg: '16px',
    full: '9999px',
  },
  shadow: {
    sm: '0 1px 2px rgba(11, 45, 91, 0.06)',
    md: '0 4px 12px rgba(11, 45, 91, 0.08)',
    lg: '0 12px 32px rgba(11, 45, 91, 0.12)',
  },
  typography: {
    
    fontFamily: "'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif",
   
    headingFontFamily: "'IBM Plex Mono', 'JetBrains Mono', ui-monospace, monospace",
    headingFontWeight: 700,
    bodyFontSize: '0.9375rem',
  },
};

export type Theme = typeof theme;
