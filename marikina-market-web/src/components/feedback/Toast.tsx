import { FC } from "react";
import ToastChild from "./ToastChild";

export type ToastType = "success" | "error" | "info" | "warning";

export interface ToastItem {
  id: string;
  type: ToastType;
  message: string;
}

interface ToastProps {
  toasts: ToastItem[];
  onDismiss: (id: string) => void;
}

const Toast: FC<ToastProps> = ({ toasts, onDismiss }) => {
  return (
    <div
      style={{
        position: "fixed",
        top: "1rem",
        right: "1rem",
        zIndex: 2000,
        display: "flex",
        flexDirection: "column",
        gap: "0.5rem",
        maxWidth: "360px",
      }}
    >
      {toasts.map((toast) => (
        <ToastChild key={toast.id} toast={toast} onDismiss={onDismiss} />
      ))}
    </div>
  );
};

export default Toast;
