
const env = {
  appName: import.meta.env.VITE_APP_NAME || 'Marikina Ticketing System',
  isProduction: import.meta.env.PROD,
  isDevelopment: import.meta.env.DEV,
};

export default env;

