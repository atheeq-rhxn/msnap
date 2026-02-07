import { Camera, Video } from "lucide-react";
import { cn } from "@/lib/utils";
import type { CaptureMode } from "@/types/capture";

interface ModeToggleProps {
  value: CaptureMode;
  onChange: (mode: CaptureMode) => void;
}

export function ModeToggle({ value, onChange }: ModeToggleProps) {
  return (
    <div className="flex items-center justify-center gap-1 p-1 bg-muted rounded-lg">
      <button
        onClick={() => onChange('screenshot')}
        className={cn(
          "flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-all duration-150",
          value === 'screenshot'
            ? "bg-primary text-primary-foreground shadow-sm"
            : "text-muted-foreground hover:text-foreground hover:bg-muted-foreground/10"
        )}
      >
        <Camera className="w-4 h-4" />
        <span>Screenshot</span>
      </button>
      
      <div className="w-px h-6 bg-border mx-1" />
      
      <button
        onClick={() => onChange('record')}
        className={cn(
          "flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-all duration-150",
          value === 'record'
            ? "bg-destructive text-destructive-foreground shadow-sm"
            : "text-muted-foreground hover:text-foreground hover:bg-muted-foreground/10"
        )}
      >
        <Video className="w-4 h-4" />
        <span>Record</span>
      </button>
    </div>
  );
}
