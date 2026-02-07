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
      className="w-full h-11 text-base font-semibold"
    >
      {isScreenshot ? (
        <>
          <Camera className="w-5 h-5 mr-2" />
          CAPTURE
        </>
      ) : (
        <>
          <Circle className="w-5 h-5 mr-2 fill-current" />
          START RECORDING
        </>
      )}
    </Button>
  );
}
