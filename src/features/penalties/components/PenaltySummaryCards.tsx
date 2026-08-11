import { FC } from 'react';
import { formatCurrency } from '@/utils/formatters';
import type { PenaltySummary } from '@/api/endpoints/penalties.api';
import styles from './PenaltySummaryCards.module.css';

interface PenaltySummaryCardsProps {
  summary: PenaltySummary;
}

const PenaltySummaryCards: FC<PenaltySummaryCardsProps> = ({ summary }) => {
  const cards = [
    { label: 'Total Unpaid', value: formatCurrency(summary.totalUnpaid), tone: 'danger' },
    { label: 'Total Collected', value: formatCurrency(summary.totalCollected), tone: 'success' },
    { label: 'Pending', value: String(summary.pendingCount), tone: 'warning' },
    { label: 'Overdue', value: String(summary.overdueCount), tone: 'danger' },
  ];

  return (
    <div className={styles.grid}>
      {cards.map((card) => (
        <div key={card.label} className={styles.card}>
          <p className={styles.label}>{card.label}</p>
          <p className={`${styles.value} ${styles[card.tone]}`}>{card.value}</p>
        </div>
      ))}
    </div>
  );
};

export default PenaltySummaryCards;
