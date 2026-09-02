export type ToastVariant = 'success' | 'error' | 'info' | 'warning';

export interface ToastOptions {
  title: string;
  description?: string;
  variant?: ToastVariant;
  duration?: number; // ms, defaults to 4000; pass 0 to require manual dismiss
}

export interface ToastItem extends ToastOptions {
  id: string;
}