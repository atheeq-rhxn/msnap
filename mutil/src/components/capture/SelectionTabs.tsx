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
    <div className="grid grid-cols-3 gap-1.5">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = value === tab.id;
        return (
          <button
            key={tab.id}
            onClick={() => onChange(tab.id)}
            className={cn(
              "flex flex-col items-center justify-center gap-1.5 rounded-lg text-xs font-medium transition-all duration-150 focus-visible:ring-1 focus-visible:ring-ring focus-visible:ring-offset-1",
              "[padding:0.625rem_0.5rem]",
              isActive
                ? "bg-primary text-primary-foreground shadow-sm"
                : "bg-muted text-muted-foreground hover:text-foreground hover:bg-muted-foreground/10"
            )}
          >
            <Icon className="w-4 h-4" aria-hidden="true" />
            <span className="text-[0.65rem]">{tab.label}</span>
          </button>
        );
      })}
    </div>
  );
}
