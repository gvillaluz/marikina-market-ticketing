import { FC, useState } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import Card from '@/components/ui/Card';
import TicketList from '@/features/tickets/components/TicketList';
import useTickets from '@/features/tickets/hooks/useTickets';
import useDebounce from '@/hooks/useDebounce';
import { formatCurrency, formatNumber } from '@/utils/formatters';
import { MARKET_SECTION_LABELS } from '@/api/types/common.types';
import styles from './TicketsPage.module.css';

const FILTERS: string[] = ['all', 'pending', 'paid', 'contested', 'overdue'];

const TicketsPage: FC = () => {
  const [status, setStatus] = useState<string>('all');
  const [search, setSearch] = useState('');
  const [marketSection, setMarketSection] = useState('');

  const debouncedSearch = useDebounce(search, 400);
  const { tickets, loading, page, totalPages, setPage, total, summary } = useTickets({
    status: status === 'all' ? undefined : status,
    search: debouncedSearch,
    marketSection: marketSection || undefined,
    pageSize: 9,
  });

  return (
    <div>
      <PageHeader
        title="Tickets"
        subtitle="Manage violations, complaints, inspections, and renewals."
      />

      <div className={styles.stats}>
        <Stat label="Total Tickets" value={summary ? formatNumber(summary.totalTickets) : '—'} change={summary?.totalTicketsChange} />
        <Stat label="Pending Payments" value={summary ? formatCurrency(summary.pendingPayments) : '—'} change={summary?.pendingPaymentsChange} />
        <Stat label="Resolved Violations" value={summary ? formatNumber(summary.resolvedViolations) : '—'} progress={summary?.resolutionRate} />
        <Stat label="Critical Severities" value={summary ? formatNumber(summary.criticalSeverities) : '—'} change={summary?.criticalSeveritiesChange} />
      </div>
      <div className={styles.toolbar}>
        <div className={styles.filters}>
          {FILTERS.map((f) => (
            <button
              key={f}
              className={`${styles.filterBtn} ${status === f ? styles.active : ''}`}
              onClick={() => setStatus(f)}
            >
              {f === 'all' ? 'All' : f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
          <select className={styles.filterBtn} value={marketSection} onChange={(event) => setMarketSection(event.target.value)} aria-label="Market Section">
            <option value="">Market Section</option>
            {Object.entries(MARKET_SECTION_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select>
        </div>
        <input
          className={styles.search}
          placeholder="Search tickets…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <TicketList tickets={tickets} loading={loading} />

      <div className={styles.entryInfo}>Showing {total === 0 ? 0 : (page - 1) * 9 + 1} to {Math.min(page * 9, total)} of {total} entries</div>

      {totalPages > 1 && (
        <div className={styles.paginationRow}>
          <button
            className={styles.pageBtn}
            disabled={page <= 1}
            onClick={() => setPage(page - 1)}
          >
            ‹ Prev
          </button>
          <span className={styles.pageInfo}>Page {page} of {totalPages}</span>
          <button
            className={styles.pageBtn}
            disabled={page >= totalPages}
            onClick={() => setPage(page + 1)}
          >
            Next ›
          </button>
        </div>
      )}

    </div>
  );
};

const Stat: FC<{ label: string; value: string; change?: number; progress?: number }> = ({ label, value, change, progress }) => (
  <Card className={styles.stat}><span className={styles.statLabel}>{label}</span><strong className={styles.statValue}>{value}</strong>{change !== undefined && <span className={styles.change}>{change >= 0 ? '+' : ''}{change}% vs last month</span>}{progress !== undefined && <div className={styles.progress}><span style={{ width: `${progress}%` }} /></div>}</Card>
);

export default TicketsPage;
