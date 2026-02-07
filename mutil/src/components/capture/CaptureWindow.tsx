import { useState } from "react";
import { X } from "lucide-react";
import { ModeToggle } from "./ModeToggle";
import { SelectionTabs } from "./SelectionTabs";
import { SourceSelect } from "./SourceSelect";
import { CaptureButton } from "./CaptureButton";
import { useWindowResize } from "@/hooks/useWindowResize";
import type { CaptureMode, SelectionType } from "@/types/capture";

interface CaptureWindowProps {
  onClose?: () => void;
}

export function CaptureWindow({ onClose }: CaptureWindowProps) {
  const [mode, setMode] = useState<CaptureMode>('screenshot');
  const [selectionType, setSelectionType] = useState<SelectionType>('region');
  const [selectedSource, setSelectedSource] = useState<string>('');

  // Hook to resize window based on selection type
  useWindowResize(selectionType);

  const handleSelectionChange = (newType: SelectionType) => {
    setSelectionType(newType);
    setSelectedSource('');
  };

  const handleCapture = () => {
    console.log('Capture:', { mode, selectionType, selectedSource });
  };

  return (
    <div className="w-full h-full rounded-xl bg-card border shadow-lg p-4 relative">
      {/* Close button */}
      <button
        onClick={onClose}
        className="absolute top-3 right-3 p-1.5 rounded-md text-muted-foreground hover:text-foreground hover:bg-muted transition-colors z-10"
        aria-label="Close"
      >
        <X className="w-4 h-4" />
      </button>

      <div className="flex flex-col gap-3 h-full">
        {/* Mode Toggle */}
        <ModeToggle value={mode} onChange={setMode} />

        {/* Divider */}
        <div className="h-px bg-border" />

        {/* Selection Tabs */}
        <SelectionTabs value={selectionType} onChange={handleSelectionChange} />

        {/* Source Select - only for Window/Screen */}
        <SourceSelect
          selectionType={selectionType}
          value={selectedSource}
          onChange={setSelectedSource}
        />

        {/* Divider */}
        <div className="h-px bg-border" />

        {/* Capture Button - centered in remaining space */}
        <div className="flex-1 flex items-center justify-center">
          <CaptureButton mode={mode} onClick={handleCapture} />
        </div>
      </div>
    </div>
  );
}
