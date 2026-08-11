import { FC } from 'react';
import Modal from '@/components/ui/Modal';
import StatusBadge from '@/components/ui/StatusBadge';
import Button from '@/components/ui/Button';
import { TICKET_TYPE_LABELS, SEVERITY_LABELS } from '@/utils/constants';
import { formatDate, formatCurrency } from '@/utils/formatters';
import type { Ticket } from '@/api/types/ticket.types';
import styles from './TicketDetailModal.module.css';

interface TicketDetailModalProps {
  ticket: Ticket;
  open: boolean;
  onClose: () => void;
  onUpdateStatus?: (ticket: Ticket, status: Ticket['status']) => void;
}

const TicketDetailModal: FC<TicketDetailModalProps> = ({ ticket, open, onClose, onUpdateStatus }) => {
  const rows: { label: string; value: string }[] = [
    { label: 'Ticket Number', value: ticket.ticketNumber },
    { label: 'Type', value: TICKET_TYPE_LABELS[ticket.type] },
    { label: 'Severity', value: SEVERITY_LABELS[ticket.severity] },
    { label: 'Vendor', value: ticket.vendorName ?? '—' },
    { label: 'Location', value: ticket.location ?? '—' },
    { label: 'Created', value: formatDate(ticket.createdAt) },
    { label: 'Due Date', value: ticket.dueDate ? formatDate(ticket.dueDate) : '—' },
    { label: 'Assigned To', value: ticket.assignedTo ?? '—' },
  ];

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={ticket.title}
      subtitle={`${ticket.ticketNumber} · ${TICKET_TYPE_LABELS[ticket.type]}`}
      size="md"
      footer={
        <>
          {onUpdateStatus && ticket.status !== 'resolved' && (
            <Button variant="success" onClick={() => onUpdateStatus(ticket, 'resolved')}>
              Mark Resolved
            </Button>
          )}
          <Button variant="outline" onClick={onClose}>
            Close
          </Button>
        </>
      }
    >
      <div className={styles.header}>
        <StatusBadge status={ticket.status} />
        <span className={styles.amount}>{ticket.amount ? formatCurrency(ticket.amount) : ''}</span>
      </div>

      <p className={styles.description}>{ticket.description}</p>

      <div className={styles.grid}>
        {rows.map((row) => (
          <div key={row.label} className={styles.row}>
            <span className={styles.label}>{row.label}</span>
            <span className={styles.value}>{row.value}</span>
          </div>
        ))}
      </div>
    </Modal>
  );
};

export default TicketDetailModal;
