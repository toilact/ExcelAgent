import react from "@vitejs/plugin-react";
import {configDefaults, defineConfig} from "vitest/config";

export default defineConfig({
  plugins: [react()],
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
    proxy: {
      "/api": {target: "http://127.0.0.1:8000", changeOrigin: true},
    },
  },
  test: {
    environment: "jsdom",
    setupFiles: ["src/test/setup.ts"],
    exclude: [...configDefaults.exclude, "e2e/**"],
    coverage: {
      provider: "v8",
      reporter: ["text"],
      thresholds: {lines: 90, functions: 90, branches: 90, statements: 90},
    },
  },
});
