import { FC } from 'react';
import StatusBadge from '@/components/ui/StatusBadge';
import Button from '@/components/ui/Button';
import { formatDate, formatCurrency } from '@/utils/formatters';
import mockAdapter from '@/api/mock/mockAdapter';
import type { Penalty } from '@/api/endpoints/penalties.api';
import styles from './PenaltyList.module.css';

interface PenaltyListProps {
  penalties: Penalty[];
  loading?: boolean;
  onMarkPaid?: (penalty: Penalty) => void;
}

const PenaltyList: FC<PenaltyListProps> = ({ penalties, loading, onMarkPaid }) => {
  if (loading) return <div className={styles.state}>Loading penalties…</div>;
  if (penalties.length === 0) return <div className={styles.state}>No penalties found.</div>;

  return (
    <div className={styles.table}>
      <div className={styles.header}>
        <span style={{ flex: 1.2 }}>Invoice</span>
        <span style={{ flex: 2 }}>Vendor</span>
        <span style={{ flex: 2 }}>Description</span>
        <span style={{ flex: 1 }}>Amount</span>
        <span style={{ flex: 1 }}>Due</span>
        <span style={{ width: 90 }}>Status</span>
        <span style={{ width: 90 }}>Action</span>
      </div>
      {penalties.map((p) => (
        <div key={p.id} className={styles.row}>
          <span style={{ flex: 1.2, fontFamily: 'monospace', fontWeight: 600 }}>{p.invoiceNumber}</span>
          <span style={{ flex: 2 }}>{p.vendorName}</span>
          <span style={{ flex: 2 }} className={styles.desc}>{p.description}</span>
          <span style={{ flex: 1, fontWeight: 700 }}>{formatCurrency(p.amount)}</span>
          <span style={{ flex: 1 }}>{formatDate(p.dueDate)}</span>
          <span style={{ width: 90 }}><StatusBadge status={p.status} /></span>
          <span style={{ width: 90 }}>
            {p.status === 'unpaid' && (
              <Button variant="success" size="sm" onClick={() => onMarkPaid?.(p)}>
                Mark Paid
              </Button>
            )}
          </span>
        </div>
      ))}
    </div>
  );
};

export default PenaltyList;
