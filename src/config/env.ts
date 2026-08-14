
const env = {
  appName: import.meta.env.VITE_APP_NAME || 'Marikina Ticketing System',
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || 'https://motocross-lifter-modified.ngrok-free.dev',
  isProduction: import.meta.env.PROD,
  isDevelopment: import.meta.env.DEV,
};

export default env;

