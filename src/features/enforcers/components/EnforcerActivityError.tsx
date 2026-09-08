import { FC } from 'react';
import { AlertTriangle } from 'lucide-react';
import styles from './EnforcerActivityPanel.module.css';

interface EnforcerActivityErrorProps {
  onRetry: () => void;
}

const EnforcerActivityError: FC<EnforcerActivityErrorProps> = ({ onRetry }) => {
  return (
    <div className={styles.errorState}>
      <AlertTriangle size={18} className={styles.errorIcon} />
      <span className={styles.errorText}>Couldn't load activity data.</span>
      <button className={styles.retryButton} onClick={onRetry}>Retry</button>
    </div>
  );
};

export default EnforcerActivityError;