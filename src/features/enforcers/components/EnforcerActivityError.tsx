import { FC } from 'react';
import { AlertTriangle } from 'lucide-react';
import styles from './EnforcerActivityPanel.module.css';

interface EnforcerActivityErrorProps {
  message: string;
  onRetry: () => void;
}

const EnforcerActivityError: FC<EnforcerActivityErrorProps> = ({ message, onRetry }) => {
  return (
    <div className={styles.errorState}>
      <AlertTriangle size={18} className={styles.errorIcon} />
      <span className={styles.errorText}>{message}</span>
      <button className={styles.retryButton} onClick={onRetry}>Retry</button>
    </div>
  );
};

export default EnforcerActivityError;