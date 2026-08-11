import { FC, useState } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import PenaltySummaryCards from '@/features/penalties/components/PenaltySummaryCards';
import PenaltyList from '@/features/penalties/components/PenaltyList';
import usePenalties from '@/features/penalties/hooks/usePenalties';
import mockAdapter from '@/api/mock/mockAdapter';
import type { Penalty } from '@/api/endpoints/penalties.api';
import styles from './PenaltiesPage.module.css';

const PenaltiesPage: FC = () => {
  const [status, setStatus] = useState<'all' | 'paid' | 'unpaid'>('all');
  const { penalties, summary, loading, refresh } = usePenalties(status === 'all' ? undefined : status);

  const handleMarkPaid = async (penalty: Penalty) => {
    await mockAdapter.markPenaltyPaid(penalty.id);
    refresh();
  };

  return (
    <div>
      <PageHeader
        title="Penalties"
        subtitle="Track fines, payments, and overdue accounts."
      />

      {summary && <PenaltySummaryCards summary={summary} />}

      <div className={styles.filters}>
        {(['all', 'paid', 'unpaid'] as const).map((f) => (
          <button
            key={f}
            className={`${styles.filterBtn} ${status === f ? styles.active : ''}`}
            onClick={() => setStatus(f)}
          >
            {f === 'all' ? 'All' : f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      <PenaltyList penalties={penalties} loading={loading} onMarkPaid={handleMarkPaid} />
    </div>
  );
};

export default PenaltiesPage;
