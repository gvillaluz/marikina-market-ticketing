import { FC } from 'react';
import StatusBadge from '@/components/ui/StatusBadge';
import { formatDate } from '@/utils/formatters';
import type { ComplianceScore } from '@/api/endpoints/compliance.api';
import styles from './ComplianceScoreCard.module.css';

interface ComplianceScoreCardProps {
  score: ComplianceScore;
}

const gradeColor: Record<string, string> = {
  A: 'var(--success)',
  B: '#16a34a',
  C: 'var(--warning)',
  D: '#ea580c',
  F: 'var(--danger)',
};

const ComplianceScoreCard: FC<ComplianceScoreCardProps> = ({ score }) => {
  return (
    <div className={styles.card}>
      <div className={styles.header}>
        <div className={styles.gradeWrap}>
          <div className={styles.grade} style={{ background: gradeColor[score.grade] }}>
            {score.grade}
          </div>
          <div>
            <h3 className={styles.name}>{score.vendorName}</h3>
            <p className={styles.score}>Overall Score: {score.overallScore}%</p>
          </div>
        </div>
        <span className={styles.updated}>Updated {formatDate(score.updatedAt)}</span>
      </div>

      <div className={styles.metrics}>
        {score.metrics.map((metric) => (
          <div key={metric.id} className={styles.metric}>
            <div className={styles.metricHeader}>
              <div>
                <p className={styles.metricName}>{metric.name}</p>
                <p className={styles.metricCategory}>{metric.category}</p>
              </div>
              <StatusBadge status={metric.status === 'compliant' ? 'approved' : metric.status === 'non-compliant' ? 'rejected' : 'pending'} />
            </div>
            <div className={styles.progressTrack}>
              <div
                className={styles.progressFill}
                style={{ width: `${metric.score}%`, background: metric.score >= 75 ? 'var(--success)' : metric.score >= 50 ? 'var(--warning)' : 'var(--danger)' }}
              />
            </div>
            <span className={styles.metricScore}>{metric.score}%</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ComplianceScoreCard;
