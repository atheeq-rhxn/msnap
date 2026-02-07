import { Camera, Video } from "lucide-react";
import { cn } from "@/lib/utils";
import type { CaptureMode } from "@/types/capture";

interface ModeToggleProps {
  value: CaptureMode;
  onChange: (mode: CaptureMode) => void;
}

export function ModeToggle({ value, onChange }: ModeToggleProps) {
  return (
    <div className="flex items-center gap-1.5 [padding:0.25rem] bg-muted rounded-lg">
      <button
        onClick={() => onChange('screenshot')}
        className={cn(
          "flex-1 flex items-center justify-center gap-2 rounded-md text-xs font-medium transition-all duration-150 focus-visible:ring-1 focus-visible:ring-ring focus-visible:ring-offset-1",
          "[padding:0.5rem_0.75rem]",
          value === 'screenshot'
            ? "bg-primary text-primary-foreground shadow-sm"
            : "text-muted-foreground hover:text-foreground hover:bg-muted-foreground/10"
        )}
      >
        <Camera className="w-3.5 h-3.5" aria-hidden="true" />
        <span>Screenshot</span>
      </button>

      <button
        onClick={() => onChange('record')}
        className={cn(
          "flex-1 flex items-center justify-center gap-2 rounded-md text-xs font-medium transition-all duration-150 focus-visible:ring-1 focus-visible:ring-ring focus-visible:ring-offset-1",
          "[padding:0.5rem_0.75rem]",
          value === 'record'
            ? "bg-destructive text-destructive-foreground shadow-sm"
            : "text-muted-foreground hover:text-foreground hover:bg-muted-foreground/10"
        )}
      >
        <Video className="w-3.5 h-3.5" aria-hidden="true" />
        <span>Record</span>
      </button>
    </div>
  );
}
