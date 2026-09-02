import { FC } from 'react';
import { CheckCircle2, XCircle, AlertTriangle, Info, X } from 'lucide-react';
import { ToastItem } from './types';
import styles from './Toast.module.css';

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
  const Icon = VARIANT_ICON[toast.variant ?? 'info'];

  return (
    <div className={`${styles.toast} ${styles[toast.variant ?? 'info']}`} role="alert">
      <Icon className={styles.icon} size={18} strokeWidth={2} aria-hidden="true" />
      <div className={styles.content}>
        <span className={styles.title}>{toast.title}</span>
        {toast.description && <span className={styles.description}>{toast.description}</span>}
      </div>
      <button className={styles.closeBtn} onClick={onDismiss} aria-label="Dismiss notification">
        <X size={14} strokeWidth={2} />
      </button>
    </div>
  );
};

export default Toast;