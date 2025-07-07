import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { Platform } from 'react-native';
import * as SecureStore from 'expo-secure-store';
import { supabase } from '@/lib/supabase';
import type { User as SupabaseUser, Session } from '@supabase/supabase-js';

interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  username?: string;
  avatarUrl?: string;
  isGuest: boolean;
  createdAt: string;
  lastLoginAt: string;
}

interface AuthState {
  user: User | null;
  session: Session | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

interface LoginCredentials {
  email: string;
  password: string;
  rememberMe?: boolean;
}

interface RegisterCredentials {
  email: string;
  password: string;
  confirmPassword: string;
  firstName: string;
  lastName: string;
  username?: string;
}

interface AuthContextType extends AuthState {
  login: (credentials: LoginCredentials) => Promise<void>;
  register: (credentials: RegisterCredentials) => Promise<void>;
  logout: () => Promise<void>;
  continueAsGuest: () => Promise<void>;
  requestPasswordReset: (email: string) => Promise<void>;
  clearError: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

type AuthAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_USER'; payload: { user: User; session: Session } }
  | { type: 'SET_ERROR'; payload: string }
  | { type: 'CLEAR_ERROR' }
  | { type: 'LOGOUT' };

const authReducer = (state: AuthState, action: AuthAction): AuthState => {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'SET_USER':
      return {
        ...state,
        user: action.payload.user,
        session: action.payload.session,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      };
    case 'SET_ERROR':
      return { ...state, error: action.payload, isLoading: false };
    case 'CLEAR_ERROR':
      return { ...state, error: null };
    case 'LOGOUT':
      return {
        user: null,
        session: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      };
    default:
      return state;
  }
};

const initialState: AuthState = {
  user: null,
  session: null,
  isAuthenticated: false,
  isLoading: true,
  error: null,
};

// Secure storage helpers
const storeSecurely = async (key: string, value: string) => {
  try {
    if (Platform.OS === 'web') {
      localStorage.setItem(key, btoa(value));
    } else {
      await SecureStore.setItemAsync(key, value);
    }
  } catch (error) {
    console.warn('Failed to store securely:', error);
  }
};

const getSecurely = async (key: string): Promise<string | null> => {
  try {
    if (Platform.OS === 'web') {
      const value = localStorage.getItem(key);
      return value ? atob(value) : null;
    } else {
      return await SecureStore.getItemAsync(key);
    }
  } catch (error) {
    console.warn('Failed to get securely:', error);
    return null;
  }
};

const deleteSecurely = async (key: string) => {
  try {
    if (Platform.OS === 'web') {
      localStorage.removeItem(key);
    } else {
      await SecureStore.deleteItemAsync(key);
    }
  } catch (error) {
    console.warn('Failed to delete securely:', error);
  }
};

// Transform Supabase user to our User type
const transformUser = (supabaseUser: SupabaseUser, userData?: any): User => {
  return {
    id: supabaseUser.id,
    email: supabaseUser.email || '',
    firstName: userData?.first_name || supabaseUser.user_metadata?.first_name || 'User',
    lastName: userData?.last_name || supabaseUser.user_metadata?.last_name || '',
    username: userData?.username || supabaseUser.user_metadata?.username,
    avatarUrl: userData?.avatar_url || supabaseUser.user_metadata?.avatar_url,
    isGuest: userData?.is_guest || false,
    createdAt: supabaseUser.created_at,
    lastLoginAt: supabaseUser.last_sign_in_at || supabaseUser.created_at,
  };
};

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(authReducer, initialState);

  // Initialize auth state on app start
  useEffect(() => {
    initializeAuth();
    
    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('Auth state changed:', event, session?.user?.id);
        
        if (session?.user) {
          await handleAuthUser(session.user, session);
        } else {
          dispatch({ type: 'LOGOUT' });
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  const initializeAuth = async () => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      // Check for guest session first
      const guestSession = await getSecurely('guest_session');
      if (guestSession) {
        const guestUser = JSON.parse(guestSession);
        const mockSession = {
          access_token: 'guest-token',
          refresh_token: 'guest-refresh',
          expires_in: 3600,
          token_type: 'bearer',
          user: {
            id: guestUser.id,
            email: guestUser.email,
            created_at: guestUser.createdAt,
          },
        } as Session;
        
        dispatch({ type: 'SET_USER', payload: { user: guestUser, session: mockSession } });
        return;
      }

      // Check for regular Supabase session
      const { data: { session }, error } = await supabase.auth.getSession();
      
      if (error) {
        console.error('Error getting session:', error);
        dispatch({ type: 'SET_ERROR', payload: error.message });
        return;
      }

      if (session?.user) {
        await handleAuthUser(session.user, session);
      }
    } catch (error) {
      console.error('Failed to initialize auth:', error);
      dispatch({ type: 'SET_ERROR', payload: 'Failed to initialize authentication' });
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  const handleAuthUser = async (supabaseUser: SupabaseUser, session: Session) => {
    try {
      // Fetch user data from our users table
      const { data: userData, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', supabaseUser.id)
        .single();

      if (error && error.code !== 'PGRST116') {
        console.error('Error fetching user data:', error);
      }

      const user = transformUser(supabaseUser, userData);
      dispatch({ type: 'SET_USER', payload: { user, session } });
    } catch (error) {
      console.error('Error handling auth user:', error);
      dispatch({ type: 'SET_ERROR', payload: 'Failed to load user data' });
    }
  };

  const login = async (credentials: LoginCredentials) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    dispatch({ type: 'CLEAR_ERROR' });

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: credentials.email,
        password: credentials.password,
      });

      if (error) {
        throw error;
      }

      if (credentials.rememberMe) {
        await storeSecurely('remember_me', 'true');
      }

      // User state will be updated via onAuthStateChange
    } catch (error: any) {
      dispatch({ type: 'SET_ERROR', payload: error.message || 'Login failed' });
      throw error;
    }
  };

  const register = async (credentials: RegisterCredentials) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    dispatch({ type: 'CLEAR_ERROR' });

    try {
      if (credentials.password !== credentials.confirmPassword) {
        throw new Error('Passwords do not match');
      }

      const { data, error } = await supabase.auth.signUp({
        email: credentials.email,
        password: credentials.password,
        options: {
          data: {
            first_name: credentials.firstName,
            last_name: credentials.lastName,
            username: credentials.username,
          },
        },
      });

      if (error) {
        throw error;
      }

      // User state will be updated via onAuthStateChange
    } catch (error: any) {
      dispatch({ type: 'SET_ERROR', payload: error.message || 'Registration failed' });
      throw error;
    }
  };

  const continueAsGuest = async () => {
    dispatch({ type: 'SET_LOADING', payload: true });
    dispatch({ type: 'CLEAR_ERROR' });

    try {
      // Create a temporary guest user
      const guestUser: User = {
        id: 'guest-' + Date.now(),
        email: '',
        firstName: 'Guest',
        lastName: 'User',
        isGuest: true,
        createdAt: new Date().toISOString(),
        lastLoginAt: new Date().toISOString(),
      };

      // Store guest session
      await storeSecurely('guest_session', JSON.stringify(guestUser));
      
      // Create a mock session for guest
      const mockSession = {
        access_token: 'guest-token',
        refresh_token: 'guest-refresh',
        expires_in: 3600,
        token_type: 'bearer',
        user: {
          id: guestUser.id,
          email: guestUser.email,
          created_at: guestUser.createdAt,
        },
      } as Session;

      dispatch({ type: 'SET_USER', payload: { user: guestUser, session: mockSession } });
    } catch (error: any) {
      dispatch({ type: 'SET_ERROR', payload: error.message || 'Failed to continue as guest' });
      throw error;
    }
  };

  const logout = async () => {
    dispatch({ type: 'SET_LOADING', payload: true });

    try {
      // Clear guest session if exists
      await deleteSecurely('guest_session');
      await deleteSecurely('remember_me');
      
      // Sign out from Supabase if not a guest
      if (state.user && !state.user.isGuest) {
        const { error } = await supabase.auth.signOut();
        if (error) {
          console.error('Logout error:', error);
        }
      }
      
      dispatch({ type: 'LOGOUT' });
    } catch (error) {
      console.error('Logout error:', error);
      // Force logout even if there's an error
      dispatch({ type: 'LOGOUT' });
    }
  };

  const requestPasswordReset = async (email: string) => {
    dispatch({ type: 'CLEAR_ERROR' });

    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/auth/reset-password`,
      });

      if (error) {
        throw error;
      }
    } catch (error: any) {
      dispatch({ type: 'SET_ERROR', payload: error.message || 'Failed to send reset email' });
      throw error;
    }
  };

  const clearError = () => {
    dispatch({ type: 'CLEAR_ERROR' });
  };

  return (
    <AuthContext.Provider
      value={{
        ...state,
        login,
        register,
        logout,
        continueAsGuest,
        requestPasswordReset,
        clearError,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};