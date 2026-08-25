import react from "@vitejs/plugin-react";
import type {Plugin} from "vite";
import {configDefaults, defineConfig} from "vitest/config";

const readinessPath = "/__excelagent/ready";

function excelAgentReadinessPlugin(): Plugin {
  const instanceChallenge = process.env.EXCEL_AGENT_UI_INSTANCE_CHALLENGE;

  return {
    name: "excel-agent-readiness",
    apply: "serve",
    configureServer(server) {
      server.middlewares.use((request, response, next) => {
        if (
          request.method !== "GET" ||
          request.url !== readinessPath ||
          instanceChallenge === undefined
        ) {
          next();
          return;
        }

        response.statusCode = 200;
        response.setHeader("Content-Type", "text/plain; charset=utf-8");
        response.setHeader("Cache-Control", "no-store");
        response.end(instanceChallenge);
      });
    },
  };
}

export default defineConfig({
  plugins: [react(), excelAgentReadinessPlugin()],
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
