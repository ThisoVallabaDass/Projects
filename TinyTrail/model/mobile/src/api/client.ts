import axios from 'axios';
import Constants from 'expo-constants';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { auth } from '../firebase/config';

const hostFromExpo =
  Constants.expoConfig?.hostUri?.split(':')[0] ||
  Constants.manifest2?.extra?.expoClient?.hostUri?.split(':')[0];

export const BASE_URL =
  process.env.EXPO_PUBLIC_API_URL ||
  Constants.expoConfig?.extra?.API_URL ||
  (hostFromExpo ? `http://${hostFromExpo}:8080/api` : 'http://10.0.2.2:8080/api');

const client = axios.create({
  baseURL: BASE_URL,
  timeout: 10000,
});

// Request interceptor to add auth token
client.interceptors.request.use(
  async (config) => {
    // Prefer fresh Firebase ID token when available.
    let token: string | null = null;
    try {
      if (auth.currentUser) {
        token = await auth.currentUser.getIdToken();
      }
    } catch (_e) {
      token = null;
    }

    if (!token) {
      token = await AsyncStorage.getItem('authToken');
    }
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle auth errors
client.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid, clear storage
      await AsyncStorage.removeItem('authToken');
      // You might want to dispatch a logout action here
    }
    return Promise.reject(error);
  }
);

export default client;
