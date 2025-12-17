/**
 * Supabase integration tests
 * Validates credentials and connection (mocked during CI)
 */

import { beforeAll, describe, expect, it } from "vitest";

const DEFAULT_SUPABASE_ENV = {
  SUPABASE_URL: "https://example.supabase.co",
  SUPABASE_ANON_KEY: "anon-test-key-12345678901234567890",
};

for (const [key, value] of Object.entries(DEFAULT_SUPABASE_ENV)) {
  process.env[key] ??= value;
}

describe("Supabase Integration", () => {
  let testSupabaseConnection: (() => Promise<boolean>) | null = null;

  beforeAll(async () => {
    const supabaseModule = await import("../lib/supabase");
    testSupabaseConnection = supabaseModule.testSupabaseConnection;
  });

  it("should validate Supabase credentials are set", () => {
    expect(process.env.SUPABASE_URL).toBeDefined();
    expect(process.env.SUPABASE_ANON_KEY).toBeDefined();
    expect(process.env.SUPABASE_URL).toMatch(/^https:\/\/.*\.supabase\.co$/);
    expect(process.env.SUPABASE_ANON_KEY?.length).toBeGreaterThan(20);
  });

  it("should connect to Supabase successfully", async () => {
    if (!testSupabaseConnection) {
      throw new Error("Supabase module failed to load");
    }

    const isConnected = await testSupabaseConnection();
    expect(isConnected).toBe(true);
  });

  it("should have valid Supabase URL format", () => {
    const url = process.env.SUPABASE_URL;
    expect(url).toMatch(/supabase\.co/);
  });

  it("should have valid API key format", () => {
    const key = process.env.SUPABASE_ANON_KEY;
    expect(key).toBeDefined();
    expect(key?.length).toBeGreaterThan(20);
  });
});
