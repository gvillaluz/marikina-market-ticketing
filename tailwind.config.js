/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#0B2D5B',
          hover: '#0A2650',
        },
        accent: {
          DEFAULT: '#B8792F',
        },
        'on-primary': '#FFFFFF',
        page: '#EEF2F8',
        surface: '#FFFFFF',
        bglight: {
          DEFAULT: '#EEF2F8',
          card: '#E9F0F8',
        },
        bodygray: '#5B6472',
        default: '#D9E1EC',
      },
      fontFamily: {
        sans: ['Inter', 'Segoe UI', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['IBM Plex Mono', 'JetBrains Mono', 'ui-monospace', 'SFMono-Regular', 'monospace'],
      },
    },
  },
  plugins: [],
};
