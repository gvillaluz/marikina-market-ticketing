import { FC } from 'react';
import TicketCard from './TicketCard';
import type { Ticket } from '@/api/types/ticket.types';
import styles from './TicketList.module.css';

interface TicketListProps {
  tickets: Ticket[];
  loading?: boolean;
}

const TicketList: FC<TicketListProps> = ({ tickets, loading }) => {
  if (loading) {
    return (
      <div className={styles.grid}>
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className={styles.skeleton} />
        ))}
      </div>
    );
  }

  if (tickets.length === 0) {
    return (
      <div className={styles.empty}>
        <span style={{ fontSize: '2.5rem' }}>🎫</span>
        <p>No tickets found.</p>
      </div>
    );
  }

  return (
    <div className={styles.grid}>
      {tickets.map((ticket) => (
        <TicketCard key={ticket.id} ticket={ticket} />
      ))}
    </div>
  );
};

export default TicketList;
