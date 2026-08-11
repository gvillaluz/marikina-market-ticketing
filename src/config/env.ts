/**
 * Environment configuration.
 * Values are read from .env / process.env via Vite's import.meta.env.
 * When the ASP.NET backend is ready, set VITE_API_BASE_URL to the live backend.
 */
const env = {
  appName: import.meta.env.VITE_APP_NAME || 'Marikina Ticketing System',
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL || 'http://localhost:5000/api',
  isProduction: import.meta.env.PROD,
  isDevelopment: import.meta.env.DEV,
  /** Set to true to run against in-memory mock adapters (no backend required). */
  useMocks: true,
};

export default env;

