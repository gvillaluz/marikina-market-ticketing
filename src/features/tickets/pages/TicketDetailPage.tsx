import { FC, useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import Loader from '@/components/feedback/Loader';
import StatusBadge from '@/components/ui/StatusBadge';
import Button from '@/components/ui/Button';
import mockAdapter from '@/api/mock/mockAdapter';
import { formatDate, formatCurrency } from '@/utils/formatters';
import { TICKET_TYPE_LABELS, SEVERITY_LABELS } from '@/utils/constants';
import type { Ticket } from '@/api/types/ticket.types';
import type { TicketHistoryEntry } from '@/api/types/ticket.types';
import styles from './TicketDetailPage.module.css';

const TicketDetailPage: FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [ticket, setTicket] = useState<Ticket | null>(null);
  const [history, setHistory] = useState<TicketHistoryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    (async () => {
      try {
        const [t, h] = await Promise.all([
          mockAdapter.getTicket(id),
          mockAdapter.getTicketHistory(id),
        ]);
        setTicket(t);
        setHistory(h);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load ticket.');
      } finally {
        setLoading(false);
      }
    })();
  }, [id]);

  const handleResolve = async () => {
    if (!ticket) return;
    const updated = await mockAdapter.updateTicketStatus(ticket.id, 'resolved');
    setTicket(updated);
  };

  if (loading) return <Loader fullPage label="Loading ticket…" />;

  if (error || !ticket) {
    return (
      <div className={styles.errorState}>
        <span style={{ fontSize: '2.5rem' }}>🔍</span>
        <h2>Ticket not found</h2>
        <p>{error}</p>
        <Button onClick={() => navigate('/tickets')}>Back to Tickets</Button>
      </div>
    );
  }

  return (
    <div>
      <Link to="/tickets" className={styles.back}>← Back to Tickets</Link>

      <div className={styles.header}>
        <div>
          <div className={styles.headerTop}>
            <h1 className={styles.title}>{ticket.title}</h1>
            <StatusBadge status={ticket.status} />
          </div>
          <p className={styles.subtitle}>
            {ticket.ticketNumber} · {TICKET_TYPE_LABELS[ticket.type]} · {SEVERITY_LABELS[ticket.severity]} severity
          </p>
        </div>
        {ticket.status !== 'resolved' && (
          <Button variant="success" onClick={handleResolve}>Mark Resolved</Button>
        )}
      </div>

      <div className={styles.grid}>
        <div className={styles.card}>
          <h3 className={styles.cardTitle}>Details</h3>
          <p className={styles.description}>{ticket.description}</p>
          <div className={styles.detailsGrid}>
            <Detail label="Vendor" value={ticket.vendorName ?? '—'} />
            <Detail label="Location" value={ticket.location ?? '—'} />
            <Detail label="Created" value={formatDate(ticket.createdAt)} />
            <Detail label="Last Updated" value={formatDate(ticket.updatedAt)} />
            <Detail label="Due Date" value={ticket.dueDate ? formatDate(ticket.dueDate) : '—'} />
            <Detail label="Assigned To" value={ticket.assignedTo ?? '—'} />
            {ticket.amount ? (
              <Detail label="Amount" value={formatCurrency(ticket.amount)} highlight />
            ) : null}
          </div>
        </div>

        <div className={styles.card}>
          <h3 className={styles.cardTitle}>History</h3>
          <div className={styles.timeline}>
            {history.map((entry) => (
              <div key={entry.id} className={styles.timelineItem}>
                <div className={styles.timelineDot} />
                <div className={styles.timelineContent}>
                  <div className={styles.timelineHeader}>
                    <span className={styles.action}>{entry.action}</span>
                    <span className={styles.time}>{formatDate(entry.timestamp)}</span>
                  </div>
                  {entry.note && <p className={styles.note}>{entry.note}</p>}
                  <span className={styles.performer}>{entry.performedBy}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

const Detail: FC<{ label: string; value: string; highlight?: boolean }> = ({ label, value, highlight }) => (
  <div>
    <p className={styles.detailLabel}>{label}</p>
    <p className={`${styles.detailValue} ${highlight ? styles.highlight : ''}`}>{value}</p>
  </div>
);

export default TicketDetailPage;
