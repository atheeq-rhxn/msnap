export type CaptureMode = 'screenshot' | 'record';
export type SelectionType = 'region' | 'window' | 'screen';

export interface WindowOption {
  id: string;
  name: string;
  icon?: string;
}

export interface ScreenOption {
  id: string;
  name: string;
  resolution: string;
}
