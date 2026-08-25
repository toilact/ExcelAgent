export type HealthResponse = {
  status: "ok";
  service: "excel-agent-api";
};

function isHealthResponse(value: unknown): value is HealthResponse {
  if (typeof value !== "object" || value === null) return false;
  const candidate = value as Record<string, unknown>;
  return candidate.status === "ok" && candidate.service === "excel-agent-api";
}

export async function bootstrapLocalSession(
  request: typeof fetch = globalThis.fetch,
): Promise<HealthResponse> {
  const token = new URLSearchParams(window.location.hash.slice(1)).get("token");
  window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}`);

  if (token !== null) {
    const bootstrap = await request("/api/bootstrap", {
      method: "POST",
      credentials: "include",
      headers: {"X-ExcelAgent-Launch-Token": token},
    });
    if (bootstrap.status !== 204) throw new Error("Local bootstrap failed");
  }

  const response = await request("/api/health", {credentials: "include"});
  if (!response.ok) throw new Error("Health request failed");
  const health: unknown = await response.json();
  if (!isHealthResponse(health)) throw new Error("Invalid health response");
  return health;
}
