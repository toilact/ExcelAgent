import {useEffect, useState} from "react";

import {bootstrapLocalSession} from "../../shared/api/bootstrap";

type ConnectionState = "connecting" | "ready" | "failed";

export function App() {
  const [state, setState] = useState<ConnectionState>("connecting");

  useEffect(() => {
    let active = true;
    void bootstrapLocalSession()
      .then(() => active && setState("ready"))
      .catch(() => active && setState("failed"));
    return () => {
      active = false;
    };
  }, []);

  return (
    <main className="health-page">
      <section className="health-card" aria-live="polite" aria-labelledby="app-title">
        <p className="eyebrow">Local workspace</p>
        <h1 id="app-title">ExcelAgent</h1>
        {state === "connecting" && <p>Connecting to ExcelAgent…</p>}
        {state === "ready" && <p>ExcelAgent is ready</p>}
        {state === "failed" && <p role="alert" lang="vi">Không thể kết nối ExcelAgent.</p>}
      </section>
    </main>
  );
}
