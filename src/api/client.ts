import axios, { AxiosError, AxiosInstance, InternalAxiosRequestConfig } from 'axios';
import env from '@/config/env';
import { useAuthStore } from '@/store/store';

/**
 * Axios instance configured for the ASP.NET backend.
 * Interceptors attach the JWT token and normalize errors.
 */
const client: AxiosInstance = axios.create({
  baseURL: env.apiBaseUrl,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach auth token to every outgoing request
client.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = useAuthStore.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// Normalize error responses
client.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
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
