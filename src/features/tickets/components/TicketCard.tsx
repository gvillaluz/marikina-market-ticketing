import { FC } from 'react';
import { useNavigate } from 'react-router-dom';
import StatusBadge from '@/components/ui/StatusBadge';
import { TICKET_TYPE_LABELS, SEVERITY_LABELS } from '@/utils/constants';
import { formatDate } from '@/utils/formatters';
import type { Ticket } from '@/api/types/ticket.types';
import styles from './TicketCard.module.css';

interface TicketCardProps {
  ticket: Ticket;
}

const severityColor: Record<string, string> = {
  low: 'var(--info)',
  medium: 'var(--warning)',
  high: 'var(--danger)',
  critical: '#7f1d1d',
};

const TicketCard: FC<TicketCardProps> = ({ ticket }) => {
  const navigate = useNavigate();

  return (
    <div className={styles.card} onClick={() => navigate(`/tickets/${ticket.id}`)}>
      <div className={styles.top}>
        <span className={styles.ticketNo}>{ticket.ticketNumber}</span>
        <StatusBadge status={ticket.status} />
      </div>

      <div className={styles.titleRow}>
        <span className={styles.typeTag}>{TICKET_TYPE_LABELS[ticket.type]}</span>
        <span className={styles.severity} style={{ color: severityColor[ticket.severity] }}>
          ● {SEVERITY_LABELS[ticket.severity]}
        </span>
      </div>

      <h3 className={styles.title}>{ticket.title}</h3>
      <p className={styles.description}>{ticket.description}</p>

      <div className={styles.meta}>
        <span>🏢 {ticket.vendorName ?? '—'}</span>
        <span>📍 {ticket.location ?? '—'}</span>
      </div>

      <div className={styles.footer}>
        <span>Created {formatDate(ticket.createdAt)}</span>
        {ticket.amount ? <span className={styles.amount}>₱{ticket.amount.toLocaleString()}</span> : null}
      </div>
    </div>
  );
};

export default TicketCard;
