import { defineConfig } from "@neon/config/v1";

export default defineConfig({
  // Declare your Neon services here
  preview: {
    realtime: true,
  },
  auth: true,
  functions: {
    hello: { name: "Hello World", source: "./hello.ts" },
    // The RADAR API (Hono): authenticated library/saved-tracks endpoints + Realtime sealing.
    radar: {
      name: "RADAR API",
      source: "./server/api.ts",
      // Realtime's secret and URL are NOT auto-injected into Functions, and the NEON_ prefix is
      // reserved for Neon-managed variables, so they are passed under RADAR_* names.
      // Deploy with:  neon deploy --env .env.local   (the values come from the git-ignored file)
      env: {
        RADAR_REALTIME_SECRET: { value: process.env.NEON_REALTIME_SECRET, required: true },
        RADAR_REALTIME_URL: { value: process.env.NEON_REALTIME_URL, required: true },
      },
    },
  },
  // Branch policy: per-branch tuning
  branch: (branch) => {
    if (branch.isDefault) {
      // Default branch: no overrides, uses project defaults
      return {};
    }
    if (!branch.exists) {
      // New non-default branches: auto-expire
      // Run `neon checkout <name>` to create a new branch with these settings
      return { ttl: "7d" };
    }
    // Existing branch: no changes
    return {};
  },
});
