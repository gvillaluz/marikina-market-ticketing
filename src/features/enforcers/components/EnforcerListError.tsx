import { FC } from 'react';
import { AlertTriangle } from 'lucide-react';
import Button from '@/components/ui/Button';
import styles from './../pages/EnforcersPage.module.css';

interface EnforcerListErrorProps {
  onRetry: () => void;
}

const EnforcerListError: FC<EnforcerListErrorProps> = ({ onRetry }) => {
  return (
    <div className={styles.listError}>
      <AlertTriangle size={28} className={styles.listErrorIcon} />
      <h3 className={styles.listErrorTitle}>Unable to load enforcers</h3>
      <p className={styles.listErrorMessage}>Something went wrong while fetching enforcer records.</p>
      <Button variant="primary" onClick={onRetry}>Try Again</Button>
    </div>
  );
};

export default EnforcerListError;