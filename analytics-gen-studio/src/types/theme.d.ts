import '@mui/material/styles';

declare module '@mui/material/styles' {
  interface Palette {
    brand: {
      events: string;
      shared: string;
      contexts: string;
      fileIcon: string;
    };
    yaml: {
      key: string;
      comment: string;
      text: string;
      boolean: string;
      number: string;
      string: string;
      null: string;
      muted: string;
      lineNumber: string;
      border: string;
      errorBadge: string;
    };
  }
  interface PaletteOptions {
    brand?: {
      events?: string;
      shared?: string;
      contexts?: string;
      fileIcon?: string;
    };
    yaml?: {
      key?: string;
      comment?: string;
      text?: string;
      boolean?: string;
      number?: string;
      string?: string;
      null?: string;
      muted?: string;
      lineNumber?: string;
      border?: string;
      errorBadge?: string;
    };
  }
}
