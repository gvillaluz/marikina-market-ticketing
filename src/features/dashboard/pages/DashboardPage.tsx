import styles from './DashboardPage.module.css';
import { useDashboardSummary } from '../hooks/useDashboardSummary';

const CARD_DEFS = [
  { key: 'totalInspectionsToday', label: "Today's Inspections" },
  { key: 'totalWarnings', label: 'Total Warnings' },
  { key: 'totalTickets', label: 'Total Tickets' },
  { key: 'totalPendingFines', label: 'Pending Fines (₱)' },
  { key: 'complianceRate', label: 'Compliance Rate (%)' },
] as const;

export function DashboardPage() {
  const { data, isLoading, isError } = useDashboardSummary();

  return (
    <div>
      <div className={styles.header}>
        <h1 className={styles.title}>Dashboard</h1>
      </div>

      {isError && <p className={styles.errorState}>Unable to load dashboard summary.</p>}

      <div className={styles.grid}>
        {CARD_DEFS.map((card) => (
          <div className={styles.card} key={card.key}>
            <p className={styles.cardLabel}>{card.label}</p>
            {isLoading ? (
              <div className={styles.skeleton} />
            ) : (
              <p className={styles.cardValue}>{data ? data[card.key] : '—'}</p>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
