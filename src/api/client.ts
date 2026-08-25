import axios, { AxiosError, AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import env from '@/config/env';
import { useAuthStore } from '@/store/store';
import snakecaseKeys from 'snakecase-keys';
import camelcaseKeys from 'camelcase-keys';


const client: AxiosInstance = axios.create({
  baseURL: `${env.apiBaseUrl}/api`,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  },
});

client.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    console.log('Sending request to:', config.url, 'Payload:', config.data);

    const token = useAuthStore.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    if (config.data && typeof config.data === 'object' && !(config.data instanceof FormData)) {
      config.data = snakecaseKeys(config.data, { deep: true });
    }

    if (config.params && typeof config.params === 'object') {
      config.params = snakecaseKeys(config.params, { deep: true });
    }
    return config;
  },
  (error) => Promise.reject(error),
);


client.interceptors.response.use(
  (response) => {
    if (response.data && typeof response.data === 'object') {
      response.data = camelcaseKeys(response.data, { deep: true });
    }

    console.log('API Response:', {
      url: response.config.url,
      status: response.status,
      params: response.config.params,
      data: response.data,
    });
    return response;
  },
  (error: AxiosError) => {
    console.log('API Error:', error.response?.status, error.response?.data);
    const isChangePasswordCall = error.config?.url?.includes('mandatory-change-password');
    if (error.response?.status === 401 && !isChangePasswordCall) {
      useAuthStore.getState().logout();
    }
    const message =
      (error.response?.data as { message?: string })?.message ||
      error.message ||
      'Something went wrong.';
    return Promise.reject(new Error(message));
  },
);

export default client;
