import { FC } from "react";
import { CheckCircle2, XCircle, AlertTriangle, Info, X } from "lucide-react";
import { ToastItem } from "./types";
import styles from "./Toast.module.css";
import Button from "@/components/ui/Button";

const VARIANT_ICON = {
  success: CheckCircle2,
  error: XCircle,
  warning: AlertTriangle,
  info: Info,
};

interface ToastProps {
  toast: ToastItem;
  onDismiss: () => void;
}

const Toast: FC<ToastProps> = ({ toast, onDismiss }) => {
  const Icon = VARIANT_ICON[toast.variant ?? "info"];

  return (
    <div
      className={`${styles.toast} ${styles[toast.variant ?? "info"]}`}
      role={
        toast.variant === "error" || toast.variant === "warning"
          ? "alert"
          : "status"
      }
      aria-atomic="true"
    >
      <Icon
        className={styles.icon}
        size={18}
        strokeWidth={2}
        aria-hidden="true"
      />
      <div className={styles.content}>
        <span className={styles.title}>{toast.title}</span>
        {toast.description && (
          <span className={styles.description}>{toast.description}</span>
        )}
        {toast.actionLabel && toast.onAction && (
          <Button
            className={styles.actionBtn}
            variant="primary"
            size="sm"
            type="button"
            onClick={() => {
              toast.onAction?.();
              onDismiss();
            }}
          >
            {toast.actionLabel}
          </Button>
        )}
      </div>
      <button
        type="button"
        className={styles.closeBtn}
        onClick={onDismiss}
        aria-label="Dismiss notification"
      >
        <X size={16} strokeWidth={2} aria-hidden="true" />
      </button>
    </div>
  );
};

export default Toast;
