import {render, screen} from "@testing-library/react";
import {beforeEach, expect, test, vi} from "vitest";

import {bootstrapLocalSession} from "../../shared/api/bootstrap";
import {App} from "./App";

const healthResponse = () =>
  new Response(JSON.stringify({status: "ok", service: "excel-agent-api"}), {
    status: 200,
    headers: {"content-type": "application/json"},
  });

beforeEach(() => {
  window.history.replaceState(null, "", "/#token=launch-secret");
  vi.restoreAllMocks();
});

test("removes the launch token before exchanging it", async () => {
  let hashAtBootstrapRequest = "launch-secret";
  const request = vi
    .fn<typeof fetch>()
    .mockImplementationOnce(() => {
      hashAtBootstrapRequest = window.location.hash;
      return Promise.resolve(new Response(null, {status: 204}));
    })
    .mockResolvedValueOnce(healthResponse());

  await bootstrapLocalSession(request);

  expect(window.location.hash).toBe("");
  expect(hashAtBootstrapRequest).toBe("");
  expect(request).toHaveBeenNthCalledWith(
    1,
    "/api/bootstrap",
    {
      method: "POST",
      credentials: "include",
      headers: {"X-ExcelAgent-Launch-Token": "launch-secret"},
    },
  );
  expect(request).toHaveBeenNthCalledWith(2, "/api/health", {credentials: "include"});
});

test("shows ready after local bootstrap and health succeed", async () => {
  vi.spyOn(globalThis, "fetch")
    .mockResolvedValueOnce(new Response(null, {status: 204}))
    .mockResolvedValueOnce(healthResponse());

  render(<App />);

  expect(screen.getByText("Connecting to ExcelAgent…")).toBeInTheDocument();
  expect(await screen.findByText("ExcelAgent is ready")).toBeInTheDocument();
});

test("shows an error when bootstrap rejects the launch token", async () => {
  vi.spyOn(globalThis, "fetch").mockResolvedValueOnce(new Response(null, {status: 401}));

  render(<App />);

  expect(await screen.findByRole("alert")).toHaveTextContent("Không thể kết nối ExcelAgent.");
});

test("only requests health when the URL has no launch token", async () => {
  window.history.replaceState(null, "", "/");
  const request = vi.fn<typeof fetch>().mockResolvedValueOnce(healthResponse());

  await bootstrapLocalSession(request);

  expect(request).toHaveBeenCalledTimes(1);
  expect(request).toHaveBeenCalledWith("/api/health", {credentials: "include"});
});

test("shows an error when health is not available", async () => {
  vi.spyOn(globalThis, "fetch")
    .mockResolvedValueOnce(new Response(null, {status: 204}))
    .mockResolvedValueOnce(new Response(null, {status: 503}));

  render(<App />);

  expect(await screen.findByRole("alert")).toHaveTextContent("Không thể kết nối ExcelAgent.");
});

test.each([
  null,
  {status: "unready", service: "excel-agent-api"},
  {status: "ok", service: "other-service"},
])("rejects malformed health payload %#", async (payload) => {
  window.history.replaceState(null, "", "/");
  const request = vi.fn<typeof fetch>().mockResolvedValueOnce(
    new Response(JSON.stringify(payload), {
      status: 200,
      headers: {"content-type": "application/json"},
    }),
  );

  await expect(bootstrapLocalSession(request)).rejects.toThrow("Invalid health response");
});
