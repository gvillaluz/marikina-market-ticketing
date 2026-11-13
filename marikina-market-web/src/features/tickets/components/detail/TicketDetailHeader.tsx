import { FC } from 'react';
import StatusPill from './StatusPill';
import ControlNumber from './ControlNumber';
import styles from './TicketDetailHeader.module.css';

import { RecordStatus } from '@/api/types/common.types';

interface TicketDetailHeaderProps {
  controlNo: string | null | undefined;
  status?: RecordStatus;
  lastUpdated: string;
}

const TicketDetailHeader: FC<TicketDetailHeaderProps> = ({ controlNo, status, lastUpdated }) => {
  return (
    <div className={styles.header}>
      <div className={styles.titleRow}>
        <h2 className={styles.title}><ControlNumber value={controlNo} /></h2>
        {status && <StatusPill variant={status} dot>{status}</StatusPill>}
      </div>
      <span className={styles.lastUpdated}>Last updated {lastUpdated}</span>
    </div>
  );
};

export default TicketDetailHeader;
