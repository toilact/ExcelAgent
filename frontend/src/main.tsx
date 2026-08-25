import {createRoot} from "react-dom/client";

import {App} from "./features/health/App";
import "./styles.css";

createRoot(document.getElementById("root")!).render(<App />);
