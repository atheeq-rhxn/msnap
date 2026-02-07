import { AppWindow, Monitor } from "lucide-react";
import type { SelectionType } from "@/types/capture";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

interface SourceSelectProps {
  selectionType: SelectionType;
  value: string;
  onChange: (value: string) => void;
}

const windowOptions = [
  { id: 'chrome', name: 'Chrome' },
  { id: 'vscode', name: 'VS Code' },
  { id: 'terminal', name: 'Terminal' },
  { id: 'finder', name: 'Finder' },
];

const screenOptions = [
  { id: 'screen1', name: 'Display 1', resolution: '1920×1080' },
  { id: 'screen2', name: 'Display 2', resolution: '2560×1440' },
];

export function SourceSelect({ selectionType, value, onChange }: SourceSelectProps) {
  if (selectionType === 'region') {
    return null;
  }

  const isWindow = selectionType === 'window';
  const options = isWindow ? windowOptions : screenOptions;
  const Icon = isWindow ? AppWindow : Monitor;
  const placeholder = isWindow ? 'Select window' : 'Select screen';

  const handleValueChange = (newValue: string | null) => {
    if (newValue !== null) {
      onChange(newValue);
    }
  };

  return (
    <div className="animate-in fade-in slide-in-from-top-1 duration-200">
      <Select value={value} onValueChange={handleValueChange}>
        <SelectTrigger className="w-full h-10">
          <Icon className="w-4 h-4 mr-2 text-muted-foreground" />
          <SelectValue placeholder={placeholder} />
        </SelectTrigger>
        <SelectContent>
          {options.map((option) => (
            <SelectItem key={option.id} value={option.id}>
              {option.name}
              {'resolution' in option && option.resolution ? ` (${option.resolution})` : ''}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}
