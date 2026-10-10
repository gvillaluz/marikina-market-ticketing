
const env = {
  appName: import.meta.env.VITE_APP_NAME || 'Marikina Ticketing System',
  apiBaseUrl: import.meta.env.DEV
    ? ''
    : (import.meta.env.VITE_API_BASE_URL || 'https://motocross-lifter-modified.ngrok-free.dev'),
  isProduction: import.meta.env.PROD,
  isDevelopment: import.meta.env.DEV,
  firebase: {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY || '',
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || '',
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || '',
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '',
    appId: import.meta.env.VITE_FIREBASE_APP_ID || '',
    vapidKey:
      import.meta.env.VITE_FIREBASE_VAPID_KEY ||
      import.meta.env.VITE_FIREBASE_KEY ||
      '',
  },
};

export const isFirebasePushConfigured = Object.values(env.firebase).every(Boolean);

export default env;

