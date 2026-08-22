import { FC } from 'react';
import { useNavigate } from 'react-router-dom';
import StatusBadge from '@/components/ui/StatusBadge';
import { TICKET_TYPE_LABELS, SEVERITY_LABELS } from '@/utils/constants';
import { formatDate } from '@/utils/formatters';
import type { TicketRecord } from '@/api/types/ticket.types';
import styles from './TicketCard.module.css';

interface TicketCardProps {
  ticket: TicketRecord;
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
        <span className={styles.ticketNo}>{ticket.controlNumber}</span>
        <StatusBadge status={ticket.status} />
      </div>

      <div className={styles.titleRow}>
        <span className={styles.typeTag}>Ticket</span>
        <span className={styles.severity} style={{ color: severityColor[ticket.penalty.severity] }}>
          ● {ticket.penalty.severity}
        </span>
      </div>

      <h3 className={styles.title}>{ticket.violationCommitted}</h3>
      <p className={styles.description}>{ticket.description}</p>

      <div className={styles.meta}>
        <span>{ticket.tradeName}</span>
        <span>{ticket.location}</span>
      </div>

      <div className={styles.footer}>
        <span>Issued {formatDate(ticket.dateTime)}</span>
        <span className={styles.amount}>₱{ticket.penalty.totalFineDue.toLocaleString()}</span>
      </div>
    </div>
  );
};

export default TicketCard;
