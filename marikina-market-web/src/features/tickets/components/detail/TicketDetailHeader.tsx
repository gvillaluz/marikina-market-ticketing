import { FC, ReactNode } from 'react';
import StatusPill from './StatusPill';
import styles from './TicketDetailHeader.module.css';

import { RecordStatus } from '@/api/types/common.types';
import { recordStatusLabel } from '@/utils/constants';

interface TicketDetailHeaderProps {
  title: ReactNode;
  status?: RecordStatus;
  lastUpdated: string;
}

const TicketDetailHeader: FC<TicketDetailHeaderProps> = ({ title, status, lastUpdated }) => {
  return (
    <div className={styles.header}>
      <div className={styles.titleRow}>
        <h2 className={styles.title}>{title}</h2>
        {status && <StatusPill variant={status} dot>{recordStatusLabel(status)}</StatusPill>}
      </div>
      <span className={styles.lastUpdated}>Last updated {lastUpdated}</span>
    </div>
  );
};

export default TicketDetailHeader;
