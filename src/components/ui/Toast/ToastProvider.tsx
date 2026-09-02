import { createContext, FC, ReactNode, useCallback, useState } from 'react';
import { createPortal } from 'react-dom';
import Toast from './Toast';
import { ToastItem, ToastOptions } from './types';
import styles from './Toast.module.css';

interface ToastContextValue {
  showToast: (options: ToastOptions) => void;
}

export const ToastContext = createContext<ToastContextValue | undefined>(undefined);

const DEFAULT_DURATION = 4000;

export const ToastProvider: FC<{ children: ReactNode }> = ({ children }) => {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const dismissToast = useCallback((id: string) => {
    setToasts((current) => current.filter((t) => t.id !== id));
  }, []);

  const showToast = useCallback((options: ToastOptions) => {
    const id = crypto.randomUUID();
    const toast: ToastItem = {
      id,
      variant: 'info',
      duration: DEFAULT_DURATION,
      ...options,
    };

    setToasts((current) => [...current, toast]);

    if (toast.duration && toast.duration > 0) {
      setTimeout(() => dismissToast(id), toast.duration);
    }
  }, [dismissToast]);

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}
      {createPortal(
        <div className={styles.viewport} role="region" aria-label="Notifications">
          {toasts.map((toast) => (
            <Toast key={toast.id} toast={toast} onDismiss={() => dismissToast(toast.id)} />
          ))}
        </div>,
        document.body
      )}
    </ToastContext.Provider>
  );
};