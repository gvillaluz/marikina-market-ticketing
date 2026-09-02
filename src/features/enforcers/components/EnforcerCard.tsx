import { FC } from 'react';
import { ArrowRight, Ticket, TriangleAlert } from 'lucide-react';
import StatusPill from '@/features/tickets/components/detail/StatusPill';
import styles from './EnforcerCard.module.css';

interface EnforcerCardProps {
  name: string;
  initials: string;
  badgeNo: string;
  status: 'Active' | 'Inactive';
  warnings: number;
  tickets: number;
  onViewInspections: () => void;
}

const EnforcerCard: FC<EnforcerCardProps> = ({
  name,
  initials,
  badgeNo,
  status,
  warnings,
  tickets,
  onViewInspections,
}) => {
  return (
    <div className={styles.card}>
      <div className={styles.header}>
        <div className={styles.avatar}>{initials}</div>
        <div className={styles.identity}>
          <span className={styles.name}>{name}</span>
          <span className={styles.badgeNo}>ID: {badgeNo}</span>
          <div className={`${styles.statusPill} ${styles[status.toLowerCase()]}`}>
            <span className={styles.dot} />
            <span className={styles.pillLabel}>{status}</span>
          </div>
        </div>
      </div>

      <div className={styles.stats}>
        <div className={styles.stat}>
          <div className={styles.statHeader}>
            <TriangleAlert size={12} color='#D37040' />
            <span className={styles.statLabel}>Warnings</span>
          </div>
          <span className={styles.statValue}>{warnings}</span>
        </div>
        <div className={styles.stat}>
          <div className={styles.statHeader}>
            <Ticket size={12} color='#00488F' />
            <span className={styles.statLabel}>Tickets</span>
          </div>
          <span className={styles.statValue}>{tickets}</span>
        </div>
      </div>

      <button className={styles.viewButton} onClick={onViewInspections}>
        View All Inspections
        <ArrowRight size={14} strokeWidth={2} />
      </button>
    </div>
  );
};

export default EnforcerCard;