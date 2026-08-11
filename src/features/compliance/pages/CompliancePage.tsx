import { FC } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import ComplianceScoreCard from '@/features/compliance/components/ComplianceScoreCard';
import useCompliance from '@/features/compliance/hooks/useCompliance';
import styles from './CompliancePage.module.css';

const CompliancePage: FC = () => {
  const { scores, loading, error } = useCompliance();

  if (loading) return <div className={styles.state}>Loading compliance data…</div>;
  if (error) return <div className={styles.state}>{error}</div>;

  return (
    <div>
      <PageHeader
        title="Compliance"
        subtitle="Vendor compliance scores across permits, health, safety, and environment."
      />

      <div className={styles.grid}>
        {scores.map((score) => (
          <ComplianceScoreCard key={score.vendorId} score={score} />
        ))}
      </div>
    </div>
  );
};

export default CompliancePage;
