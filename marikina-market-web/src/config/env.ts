
const env = {
  appName: import.meta.env.VITE_APP_NAME || 'Marikina Ticketing System',
  // The server's address, set when building the website. Empty in development, where /api is forwarded to the local server.
  apiBaseUrl: `${import.meta.env.VITE_API_BASE_URL || ''}/api`,
  isProduction: import.meta.env.PROD,
  isDevelopment: import.meta.env.DEV,
};

export default env;

