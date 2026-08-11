/**
 * Design tokens for the Marikina Public Market Inspection System.
 *
 * Shared source of truth for colors and typography used across all screens.
 * Marikina public market branding — navy / amber with light blue-gray surfaces.
 */
export const theme = {
  colors: {
    /**
     * Navy — primary brand color. Logo text, headings, primary buttons,
     * active nav states, sidebar/panel backgrounds.
     */
    primary: '#0B2D5B',

    /**
     * Slightly darker navy for button/link hover.
     */
    primaryHover: '#0A2650',

    /**
     * Amber/orange — accent color for CTAs, highlights, eyebrows, step
     * numbers, progress/chart bars.
     */
    accent: '#B8792F',

    /**
     * Darker amber for CTA hover.
     */
    accentHover: '#A66A24',

    /**
     * Light blue-gray — overall page background.
     */
    bgPage: '#EEF2F8',

    /**
     * Card background — light blue-gray, slightly deeper than page bg.
     */
    bgCard: '#E9F0F8',

    /**
     * White surface — form panels, navbar, modal/card surfaces.
     */
    bgSurface: '#FFFFFF',

    /**
     * Default border — input borders, dividers, card outlines.
     */
    borderDefault: '#D9E1EC',

    /**
     * Heading text — same as primary navy.
     */
    textHeading: '#0B2D5B',

    /**
     * Body text — paragraph/description copy.
     */
    textBody: '#5B6472',

    /**
     * Muted text — placeholder text, inactive stepper labels.
     */
    textMuted: '#94A0B2',

    /**
     * Text/icons sitting on navy backgrounds.
     */
    textOnPrimary: '#FFFFFF',

    /**
     * Status colors for hotspot/ranking levels in the analytics preview.
     */
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
    /**
     * Body font — clean sans-serif.
     */
    fontFamily: "'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif",
    /**
     * Heading font — monospace, bold, used only for section/page headings.
     */
    headingFontFamily: "'IBM Plex Mono', 'JetBrains Mono', ui-monospace, monospace",
    headingFontWeight: 700,
    bodyFontSize: '0.9375rem',
  },
};

export type Theme = typeof theme;
