import { createClient } from '@supabase/supabase-js';
import { Database } from '@/types/database';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl) {
  console.error('Missing EXPO_PUBLIC_SUPABASE_URL environment variable');
  throw new Error('Missing Supabase URL. Please check your .env file.');
}

if (!supabaseAnonKey) {
  console.error('Missing EXPO_PUBLIC_SUPABASE_ANON_KEY environment variable');
  throw new Error('Missing Supabase Anon Key. Please check your .env file.');
}

console.log('Supabase URL:', supabaseUrl);
console.log('Supabase Key exists:', !!supabaseAnonKey);

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});