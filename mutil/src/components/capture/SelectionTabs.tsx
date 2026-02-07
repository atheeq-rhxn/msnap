import { Scan, AppWindow, Monitor } from "lucide-react";
import { cn } from "@/lib/utils";
import type { SelectionType } from "@/types/capture";

interface SelectionTabsProps {
  value: SelectionType;
  onChange: (type: SelectionType) => void;
}

const tabs = [
  { id: 'region' as const, label: 'Region', icon: Scan },
  { id: 'window' as const, label: 'Window', icon: AppWindow },
  { id: 'screen' as const, label: 'Screen', icon: Monitor },
];

export function SelectionTabs({ value, onChange }: SelectionTabsProps) {
  return (
    <div className="flex items-center gap-2">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = value === tab.id;
        
        return (
          <button
            key={tab.id}
            onClick={() => onChange(tab.id)}
            className={cn(
              "flex-1 flex flex-col items-center gap-1.5 px-3 py-3 rounded-lg text-xs font-medium transition-all duration-150",
              isActive
                ? "bg-primary text-primary-foreground shadow-sm"
                : "bg-muted text-muted-foreground hover:text-foreground hover:bg-muted-foreground/10"
            )}
          >
            <Icon className="w-5 h-5" />
            <span>{tab.label}</span>
          </button>
        );
      })}
    </div>
  );
}
