import { useEffect, useRef } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import type { SelectionType } from "@/types/capture";

const WIDTH = 320;
const BASE_HEIGHT = 240;
const DROPDOWN_HEIGHT = 44;

export function useWindowResize(selectionType: SelectionType) {
  const currentHeightRef = useRef(BASE_HEIGHT);

  useEffect(() => {
    const resizeWindow = async () => {
      try {
        const window = getCurrentWindow();
        const targetHeight =
          selectionType === "region"
            ? BASE_HEIGHT
            : BASE_HEIGHT + DROPDOWN_HEIGHT;

        // Only resize if height actually changed
        if (currentHeightRef.current !== targetHeight) {
          currentHeightRef.current = targetHeight;

          // Use LogicalSize for proper DPI handling
          const { LogicalSize } = await import("@tauri-apps/api/dpi");
          const size = new LogicalSize(WIDTH, targetHeight);

          await window.setSize(size);

          // Re-center window after resize to keep it in same position
          await window.center();
        }
      } catch (error) {
        console.error("Failed to resize window:", error);
      }
    };

    // Small delay to let animation start first
    const timer = setTimeout(resizeWindow, 50);
    return () => clearTimeout(timer);
  }, [selectionType]);
}
