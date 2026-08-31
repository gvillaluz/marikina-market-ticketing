import { FC } from 'react';
import styles from './TicketDetailFooter.module.css';
import { SquareCheck } from 'lucide-react';

interface TicketDetailFooterProps {
  onViewFullRecord: () => void;
  onChangeStatus: () => void;
}

const TicketDetailFooter: FC<TicketDetailFooterProps> = ({ onViewFullRecord, onChangeStatus }) => {
  return (
    <div className={styles.footer}>
      <button type="button" className={styles.linkBtn} onClick={onViewFullRecord}>
        View Full Ticket Record
      </button>
      <button className={styles.changeBtn} onClick={onChangeStatus}>
        <SquareCheck size={20} strokeWidth={3} />
        <span className={styles.btnLabel}>Change Status</span>
      </button>
    </div>
  );
};

export default TicketDetailFooter;