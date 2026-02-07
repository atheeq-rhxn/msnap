import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { CaptureWindow } from "@/components/capture/CaptureWindow";
import "@/styles.css";

function App() {
  return (
    <CaptureWindow />
  );
}

const rootElement = document.getElementById("app");
if (rootElement) {
  createRoot(rootElement).render(
    <StrictMode>
      <App />
    </StrictMode>
  );
}
