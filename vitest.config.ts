import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["functions/test/**/*.test.ts", "test/rules/**/*.test.ts"],
    // The emulator is slower to answer than the 5s default, mostly on the first
    // transaction of a run.
    testTimeout: 20000,
    hookTimeout: 30000,
    // Firestore transactions in these tests deliberately contend with each
    // other; running files in parallel against one emulator makes failures hard
    // to attribute.
    fileParallelism: false,
  },
});
