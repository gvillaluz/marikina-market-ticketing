import { FC, useState } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import { Dropdown } from '@/components/ui/Dropdown';
import { Search } from 'lucide-react';
import EnforcerCard from '../components/EnforcerCard';
import EnforcerActivityPanel from '../components/EnforcerActivityPanel';
import styles from './EnforcersPage.module.css';

// STATIC DATA — replace with useEnforcers(queryParams) once the endpoint exists,
// following the same shape/pattern as useTickets/useTicketFilters.
const ENFORCERS = Array.from({ length: 9 }).map((_, i) => ({
  id: `enf-${i}`,
  name: 'Lee, Angelo P.',
  initials: 'LA',
  badgeNo: 'ENF-2024-012',
  status: 'Active' as const,
  warnings: 42,
  tickets: 3,
}));

const STATUS_FILTERS = ['All', 'Active Duty', 'Off Duty', 'Suspended'];
const SORT_OPTIONS = ['Name (A-Z)', 'Name (Z-A)', 'Most Tickets', 'Most Warnings'];

const PAGE_SIZE = 9;
// STATIC DATA — total entry count for the pagination footer.
const TOTAL_ENTRIES = 42;

const EnforcersPage: FC = () => {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [sort, setSort] = useState('Name (A-Z)');
  const [page, setPage] = useState(1);

  const totalPages = Math.max(1, Math.ceil(TOTAL_ENTRIES / PAGE_SIZE));

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

  return (
    <div>
      <PageHeader
        title="Enforcer Performance Records"
        subtitle="Monitor duty records for market enforcers."
      />

      <div className={styles.layout}>
        <section className={styles.recordsContainer}>
          <div className={styles.toolbar}>
            <div className={styles.searchWrapper}>
              <Search className={styles.searchIcon} size={14} strokeWidth={1.8} aria-hidden="true" />
              <input
                className={styles.searchInput}
                placeholder="Search by name or ID…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>

            <div className={styles.filterGroup}>
              <Dropdown
                ariaLabel="Filter by Status"
                triggerLabel={`Filter by Status`}
                value={statusFilter}
                onChange={(value) => setStatusFilter(value)}
                options={STATUS_FILTERS.map((filter) => ({ value: filter, label: filter }))}
              />
              <Dropdown
                ariaLabel="Sort"
                triggerLabel={sort}
                value={sort}
                onChange={(value) => setSort(value)}
                options={SORT_OPTIONS.map((option) => ({ value: option, label: option }))}
              />
            </div>
          </div>

          <div className={styles.grid}>
            {/* STATIC DATA — ENFORCERS array mapped into cards */}
            {ENFORCERS.map((enforcer) => (
              <EnforcerCard
                key={enforcer.id}
                name={enforcer.name}
                initials={enforcer.initials}
                badgeNo={enforcer.badgeNo}
                status={enforcer.status}
                warnings={enforcer.warnings}
                tickets={enforcer.tickets}
                onViewInspections={() => {
                  // TODO: navigate to /enforcers/:id or open an inspections modal
                }}
              />
            ))}
          </div>

          <div className={styles.footer}>
            <span className={styles.entries}>
              Showing {(page - 1) * PAGE_SIZE + 1} to {Math.min(page * PAGE_SIZE, TOTAL_ENTRIES)} of {TOTAL_ENTRIES} entries
            </span>

            <div className={styles.pagination}>
              <button
                className={styles.pageButton}
                disabled={page <= 1}
                onClick={() => goToPage(page - 1)}
                aria-label="Previous page"
              >
                ‹
              </button>
              {Array.from({ length: Math.min(totalPages, 3) }, (_, index) => index + 1).map((p) => (
                <button
                  key={p}
                  className={`${styles.pageButton} ${page === p ? styles.currentPage : ''}`}
                  onClick={() => goToPage(p)}
                  aria-label={`Go to page ${p}`}
                >
                  {p}
                </button>
              ))}
              {totalPages > 3 && <span className={styles.ellipsis}>...</span>}
              <button
                className={styles.pageButton}
                disabled={page >= totalPages}
                onClick={() => goToPage(page + 1)}
                aria-label="Next page"
              >
                ›
              </button>
            </div>
          </div>
        </section>

        <EnforcerActivityPanel />
      </div>
    </div>
  );
};

export default EnforcersPage;