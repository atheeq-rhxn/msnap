import { Camera, Circle } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { CaptureMode } from "@/types/capture";

interface CaptureButtonProps {
  mode: CaptureMode;
  onClick?: () => void;
}

export function CaptureButton({ mode, onClick }: CaptureButtonProps) {
  const isScreenshot = mode === 'screenshot';

  return (
    <Button
      onClick={onClick}
      variant={isScreenshot ? 'default' : 'destructive'}
      size="sm"
      className="w-full h-9 text-xs font-semibold shadow-sm hover:shadow-md transition-all rounded-lg"
    >
      {isScreenshot ? (
        <>
          <Camera className="w-4 h-4 [margin-right:0.5rem]" aria-hidden="true" />
          Capture
        </>
      ) : (
        <>
          <Circle className="w-4 h-4 [margin-right:0.5rem] fill-current" aria-hidden="true" />
          Start Recording
        </>
      )}
    </Button>
  );
}
