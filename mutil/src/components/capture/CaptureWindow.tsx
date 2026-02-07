import { useState } from "react";
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

  useWindowResize(selectionType);

  const handleSelectionChange = (newType: SelectionType) => {
    setSelectionType(newType);
    setSelectedSource('');
  };

  const handleCapture = () => {
    console.log('Capture:', { mode, selectionType, selectedSource });
  };

  return (
    <div className="w-full h-full flex items-center justify-center [padding:0.375rem]">
      <div className="w-full rounded-xl bg-card border shadow-xl [padding:0.75rem]">
        <div className="flex flex-col gap-3">
          <ModeToggle value={mode} onChange={setMode} />

          <SelectionTabs value={selectionType} onChange={handleSelectionChange} />

          <SourceSelect
            selectionType={selectionType}
            value={selectedSource}
            onChange={setSelectedSource}
          />

          <CaptureButton mode={mode} onClick={handleCapture} />
        </div>
      </div>
    </div>
  );
}
