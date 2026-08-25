import {expect, test} from "@playwright/test";

const launchToken = "excel-agent-browser-e2e-launch-token";
const uiOrigin = "http://127.0.0.1:5173";

test("removes the fragment and establishes the real local browser session", async ({page}) => {
  let bootstrapStatus: number | undefined;
  page.on("response", (response) => {
    if (response.url() === `${uiOrigin}/api/bootstrap`) {
      bootstrapStatus = response.status();
    }
  });
  await page.addInitScript(() => {
    const observedWindow = window as Window & {hashAtBootstrap?: string};
    const originalFetch = window.fetch.bind(window);
    window.fetch = (input, init) => {
      const requestUrl =
        typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
      if (requestUrl.endsWith("/api/bootstrap")) {
        observedWindow.hashAtBootstrap = window.location.hash;
      }
      return originalFetch(input, init);
    };
  });

  await page.goto(`/#token=${launchToken}`);

  await expect(page.getByText("ExcelAgent is ready")).toBeVisible();
  await expect.poll(() => new URL(page.url()).hash).toBe("");
  await expect.poll(() => bootstrapStatus).toBe(204);
  expect(await page.evaluate(() => (window as Window & {hashAtBootstrap?: string}).hashAtBootstrap))
    .toBe("");

  const reuse = await page.request.post("http://127.0.0.1:8000/api/bootstrap", {
    headers: {
      Origin: uiOrigin,
      "X-ExcelAgent-Launch-Token": launchToken,
    },
  });
  expect(reuse.status()).toBe(401);

  const protectedStatus = await page.evaluate(async () => {
    const response = await fetch("/api/not-yet-implemented", {credentials: "include"});
    return response.status;
  });
  expect(protectedStatus).toBe(404);
});
