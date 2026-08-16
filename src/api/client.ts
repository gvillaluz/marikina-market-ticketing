import axios, { AxiosError, AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import env from '@/config/env';
import { useAuthStore } from '@/store/store';


const client: AxiosInstance = axios.create({
  baseURL: `${env.apiBaseUrl}/api`,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

client.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    console.log('Sending request to:', config.url, 'Payload:', config.data);

    const token = useAuthStore.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);


client.interceptors.response.use(
  (response) => response,
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
