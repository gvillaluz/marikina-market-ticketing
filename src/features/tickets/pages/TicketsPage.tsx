import { FC, useState } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import Button from '@/components/ui/Button';
import TicketList from '@/features/tickets/components/TicketList';
import CreateTicketModal from '@/features/tickets/components/CreateTicketModal';
import useTickets from '@/features/tickets/hooks/useTickets';
import useDebounce from '@/hooks/useDebounce';
import { useAuth } from '@/context/AuthContext';
import type { Status } from '@/api/types/common.types';
import styles from './TicketsPage.module.css';

const FILTERS: (Status | 'all')[] = ['all', 'pending', 'approved', 'resolved'];

const TicketsPage: FC = () => {
  const { isAdmin } = useAuth();
  const [status, setStatus] = useState<Status | 'all'>('all');
  const [search, setSearch] = useState('');
  const [createOpen, setCreateOpen] = useState(false);

  const debouncedSearch = useDebounce(search, 400);
  const { tickets, loading, page, totalPages, setPage, refresh } = useTickets({
    status: status === 'all' ? undefined : status,
    search: debouncedSearch,
    pageSize: 9,
  });

  return (
    <div>
      <PageHeader
        title="Tickets"
        subtitle="Manage violations, complaints, inspections, and renewals."
        actions={
          isAdmin && (
            <Button onClick={() => setCreateOpen(true)}>+ New Ticket</Button>
          )
        }
      />

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
        </div>
        <input
          className={styles.search}
          placeholder="Search tickets…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <TicketList tickets={tickets} loading={loading} />

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

      <CreateTicketModal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onCreated={refresh}
      />
    </div>
  );
};

export default TicketsPage;
