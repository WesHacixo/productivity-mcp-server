/**
 * Supabase client initialization and configuration
 * Handles authentication and real-time database connections
 */

import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const isTestEnvironment = process.env.NODE_ENV === "test";

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    "Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables."
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
  },
});

/**
 * Test Supabase connection and credentials
 */
export async function testSupabaseConnection(): Promise<boolean> {
  if (isTestEnvironment) {
    // Skip real network calls during Vitest runs so tests can be self-contained.
    return true;
  }

  try {
    const { data, error } = await supabase.auth.getSession();
    if (error && error.message !== "Auth session missing!") {
      console.error("Supabase connection error:", error);
      return false;
    }
    console.log("Supabase connection successful");
    return true;
  } catch (error) {
    console.error("Failed to test Supabase connection:", error);
    return false;
  }
}

/**
 * Sign up with email and password
 */
export async function signUp(email: string, password: string) {
  return supabase.auth.signUp({
    email,
    password,
  });
}

/**
 * Sign in with email and password
 */
export async function signIn(email: string, password: string) {
  return supabase.auth.signInWithPassword({
    email,
    password,
  });
}

/**
 * Sign out current user
 */
export async function signOut() {
  return supabase.auth.signOut();
}

/**
 * Get current user session
 */
export async function getCurrentUser() {
  const { data, error } = await supabase.auth.getSession();
  if (error) {
    console.error("Error getting current user:", error);
    return null;
  }
  return data.session?.user || null;
}

/**
 * Listen to auth state changes
 */
export function onAuthStateChange(callback: (user: any) => void) {
  return supabase.auth.onAuthStateChange((event: any, session: any) => {
    callback(session?.user || null);
  });
}
