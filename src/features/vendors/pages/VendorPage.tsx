import { FC, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import PageHeader from '@/components/ui/PageHeader';
import Button from '@/components/ui/Button';
import useVendors from '@/features/vendors/hooks/useVendors';
import useDebounce from '@/hooks/useDebounce';
import { useAuth } from '@/context/AuthContext';
import { CATEGORY_LABELS } from '@/utils/constants';
import { formatDate } from '@/utils/formatters';
import StatusBadge from '@/components/ui/StatusBadge';
import styles from './VendorPage.module.css';
import type { Vendor } from '@/api/types/vendor.types';
import type { Status } from '@/api/types/common.types';

const FILTERS: (Status | 'all')[] = ['all', 'pending', 'active', 'suspended'];

const VendorsPage: FC = () => {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [status, setStatus] = useState<Status | 'all'>('all');
  const [search, setSearch] = useState('');
  const debouncedSearch = useDebounce(search, 400);

  const { vendors, loading, page, totalPages, setPage } = useVendors({
    status: status === 'all' ? undefined : status,
    search: debouncedSearch,
    pageSize: 10,
  });

  const handleRowClick = (vendor: Vendor) => navigate(`/vendors/${vendor.id}`);

  return (
    <div>
      <PageHeader
        title="Vendors"
        subtitle="Registered businesses and their compliance status."
        actions={
          isAdmin && (
            <Button onClick={() => navigate('/vendor/register')}>+ Add Vendor</Button>
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
          placeholder="Search vendors…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <div className={styles.tableCard}>
        <div className={styles.tableHeader}>
          <span style={{ flex: 2 }}>Business</span>
          <span style={{ flex: 1 }}>Category</span>
          <span style={{ flex: 1 }}>Barangay</span>
          <span style={{ flex: 1 }}>Registered</span>
          <span style={{ width: 110 }}>Status</span>
        </div>
        {loading ? (
          <div className={styles.loading}>Loading vendors…</div>
        ) : vendors.length === 0 ? (
          <div className={styles.empty}>No vendors found.</div>
        ) : (
          vendors.map((v) => (
            <div
              key={v.id}
              className={styles.row}
              onClick={() => handleRowClick(v)}
            >
              <div className={styles.businessCell} style={{ flex: 2 }}>
                <div className={styles.avatar}>{v.businessName.charAt(0)}</div>
                <div>
                  <p className={styles.businessName}>{v.businessName}</p>
                  <p className={styles.owner}>{v.contactPerson}</p>
                </div>
              </div>
              <span style={{ flex: 1 }}>{CATEGORY_LABELS[v.category] ?? v.category}</span>
              <span style={{ flex: 1 }}>{v.barangay}</span>
              <span style={{ flex: 1 }}>{formatDate(v.registrationDate)}</span>
              <span style={{ width: 110 }}>
                <StatusBadge status={v.status} />
              </span>
            </div>
          ))
        )}
      </div>

      {totalPages > 1 && (
        <div className={styles.paginationRow}>
          <button className={styles.pageBtn} disabled={page <= 1} onClick={() => setPage(page - 1)}>
            ‹ Prev
          </button>
          <span className={styles.pageInfo}>Page {page} of {totalPages}</span>
          <button className={styles.pageBtn} disabled={page >= totalPages} onClick={() => setPage(page + 1)}>
            Next ›
          </button>
        </div>
      )}
    </div>
  );
};

export default VendorsPage;
