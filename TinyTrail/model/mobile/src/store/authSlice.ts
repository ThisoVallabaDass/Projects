import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import AsyncStorage from '@react-native-async-storage/async-storage';
import client, { BASE_URL } from '../api/client';
import { auth } from '../firebase/config';
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';

export interface User {
  uid: string;
  name: string;
  email: string;
  phone: string;
  role: 'BUYER' | 'SELLER';
  pincode?: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: AuthState = {
  user: null,
  token: null,
  isLoading: false,
  error: null,
};

const getApiErrorMessage = (error: any, fallback: string) => {
  if (error?.response?.data?.error) {
    return error.response.data.error;
  }

  if (error?.message === 'Network Error') {
    return `Could not reach the TinyTrail backend at ${BASE_URL}. Start the backend, keep phone and laptop on the same Wi-Fi, and allow port 8080 through Windows Firewall.`;
  }

  return fallback;
};

// Async thunks
export const login = createAsyncThunk(
  'auth/login',
  async (credentials: { identifier: string; password: string }, { rejectWithValue }) => {
    try {
      const identifier = credentials.identifier.trim().toLowerCase();
      const password = credentials.password;

      if (!identifier.includes('@')) {
        return rejectWithValue('Please login using your email address (Gmail).');
      }

      const userCredential = await signInWithEmailAndPassword(auth, identifier, password);
      const token = await userCredential.user.getIdToken();
      await AsyncStorage.setItem('authToken', token);

      // Fetch profile from backend (Firestore) to get role, phone, etc.
      const response = await client.get('/user/me', {
        headers: { Authorization: `Bearer ${token}` },
      });

      return { token, user: response.data as User };
    } catch (error: any) {
      return rejectWithValue(getApiErrorMessage(error, 'Login failed'));
    }
  }
);

export const register = createAsyncThunk(
  'auth/register',
  async (
    userData: { username: string; email: string; phone: string; password: string; role: 'BUYER' | 'SELLER' },
    { rejectWithValue }
  ) => {
    try {
      const email = userData.email.trim().toLowerCase();
      if (!email.includes('@')) {
        return rejectWithValue('Please register using a valid email address (Gmail).');
      }

      const userCredential = await createUserWithEmailAndPassword(auth, email, userData.password);
      const token = await userCredential.user.getIdToken();
      await AsyncStorage.setItem('authToken', token);

      // Create / upsert Firestore user profile via backend
      const role = userData.role === 'SELLER' ? 'vendor' : 'customer';
      await client.post(
        '/auth/profile',
        {
          name: userData.username,
          phone: String(userData.phone || ''),
          role,
        },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      const response = await client.get('/user/me', {
        headers: { Authorization: `Bearer ${token}` },
      });

      return { token, user: response.data as User };
    } catch (error: any) {
      return rejectWithValue(getApiErrorMessage(error, 'Registration failed'));
    }
  }
);

export const loadStoredAuth = createAsyncThunk(
  'auth/loadStored',
  async () => {
    const token = await AsyncStorage.getItem('authToken');
    if (token) {
      // Verify token with backend
      try {
        const response = await client.get('/user/me', {
          headers: { Authorization: `Bearer ${token}` }
        });
        return { token, user: response.data };
      } catch (error) {
        // Token invalid, remove it
        await AsyncStorage.removeItem('authToken');
        throw error;
      }
    }
    throw new Error('No stored token');
  }
);

export const logout = createAsyncThunk(
  'auth/logout',
  async () => {
    await AsyncStorage.removeItem('authToken');
    try {
      await signOut(auth);
    } catch (_e) {
      // ignore
    }
  }
);

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Login
      .addCase(login.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
        state.error = null;
      })
      .addCase(login.rejected, (state, action) => {
        state.isLoading = false;
        state.error = (action.payload as string) || action.error.message || 'Login failed';
      })
      // Register
      .addCase(register.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(register.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
        state.error = null;
      })
      .addCase(register.rejected, (state, action) => {
        state.isLoading = false;
        state.error = (action.payload as string) || action.error.message || 'Registration failed';
      })
      // Load stored auth
      .addCase(loadStoredAuth.fulfilled, (state, action) => {
        state.user = action.payload.user;
        state.token = action.payload.token;
      })
      // Logout
      .addCase(logout.fulfilled, (state) => {
        state.user = null;
        state.token = null;
        state.error = null;
      });
  },
});

export const { clearError } = authSlice.actions;
export default authSlice.reducer;
