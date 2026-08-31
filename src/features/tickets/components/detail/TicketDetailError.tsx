import { FC } from 'react';
import { Link } from 'react-router-dom';
import { AlertTriangle } from 'lucide-react';
import Button from '@/components/ui/Button';
import styles from './TicketDetailError.module.css';

interface TicketDetailErrorProps {
  message?: string;
  onRetry: () => void;
}

const TicketDetailError: FC<TicketDetailErrorProps> = ({
  message = 'Something went wrong while fetching ticket details. Please try again.',
  onRetry,
}) => {
  return (
    <div className={styles.wrapper}>
      <AlertTriangle className={styles.icon} size={32} strokeWidth={1.6} aria-hidden="true" />
      <h3 className={styles.title}>Unable to load this ticket</h3>
      <p className={styles.message}>{message}</p>
      <div className={styles.actions}>
        <Button variant="primary" onClick={onRetry}>Try Again</Button>
        <Link to="/tickets" className={styles.backLink}>Back to Tickets</Link>
      </div>
    </div>
  );
};

export default TicketDetailError;