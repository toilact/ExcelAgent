import {defineConfig} from "@playwright/test";

const launchToken = "excel-agent-browser-e2e-launch-token";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  workers: 1,
  use: {
    baseURL: "http://127.0.0.1:5173",
    trace: "retain-on-failure",
  },
  webServer: [
    {
      command:
        "uv --directory ../backend run uvicorn excel_agent.api.app:create_app --factory --host 127.0.0.1 --port 8000",
      env: {EXCEL_AGENT_LAUNCH_TOKEN: launchToken},
      url: "http://127.0.0.1:8000/api/health",
      reuseExistingServer: false,
      timeout: 30_000,
    },
    {
      command: "npm run dev -- --host 127.0.0.1 --port 5173",
      url: "http://127.0.0.1:5173",
      reuseExistingServer: false,
      timeout: 30_000,
    },
  ],
});
