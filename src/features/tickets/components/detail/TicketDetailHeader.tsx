import { FC } from 'react';
import StatusPill from './StatusPill';
import styles from './TicketDetailHeader.module.css';
import { TicketStatus } from '../../tickets.types';
import { RecordStatus, Severity } from '@/api/types/common.types';

interface TicketDetailHeaderProps {
  controlNo: string;
  status: RecordStatus;
  lastUpdated: string;
}

const TicketDetailHeader: FC<TicketDetailHeaderProps> = ({ controlNo, status, lastUpdated }) => {
  return (
    <div className={styles.header}>
      <div className={styles.titleRow}>
        <h2 className={styles.title}>Ticket #{controlNo}</h2>
        <StatusPill variant={status} dot>{status}</StatusPill>
      </div>
      <span className={styles.lastUpdated}>Last updated {lastUpdated}</span>
    </div>
  );
};

export default TicketDetailHeader;