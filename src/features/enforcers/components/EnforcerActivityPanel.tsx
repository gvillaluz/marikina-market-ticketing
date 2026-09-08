import { FC } from 'react';
import EnforcerHighlightItem from './EnforcerHighlightItem';
import TopIssuerRow from './TopIssuerRow';
import styles from './EnforcerActivityPanel.module.css';
import { TopIssuer } from '@/api/types/enforcer.types';
import EnforcerActivitySkeleton from './EnforcerActivitySkeleton';
import EnforcerActivityError from './EnforcerActivityError';
import { Trophy } from 'lucide-react';

// STATIC DATA — replace with useEnforcerAnalytics() once the endpoint exists.
const ACTIVITY_STATS = {
  avgWarningsPerDay: 6.1,
  avgTicketsPerDay: 3.1,
};

// STATIC DATA — highlight callouts, likely derived server-side (biggest change week over week, etc.)
const HIGHLIGHTS = [
  { id: 'h1', name: 'Villanueva, Mark', note: '5 warnings with no fine, this week.' },
  { id: 'h2', name: 'Ramos, Benigno P.', note: 'Top issuer this week, 9 warnings and 1 ticket.' },
];

// STATIC DATA — top issuers this month leaderboard
const TOP_ISSUERS = [
  { id: 't1', name: 'Lee, Angelo P.', count: 31 },
  { id: 't2', name: 'Lee, Angelo P.', count: 31 },
  { id: 't3', name: 'Lee, Angelo P.', count: 31 },
  { id: 't4', name: 'Lee, Angelo P.', count: 31 },
  { id: 't5', name: 'Lee, Angelo P.', count: 31 },
];

type EnforcerActivityProps = {
  averageTicket: number;
  averageWarning: number;
  topEnforcers: TopIssuer[];
  isLoading: boolean;
  isError: boolean;
  onRetry: () => void;
};


const EnforcerActivityPanel: FC<EnforcerActivityProps> = ({ 
  averageTicket, 
  averageWarning,
  topEnforcers,
  isLoading,
  isError,
  onRetry
 }) => {
  return (
    <aside className={styles.panel}>
      <h5 className={styles.title}>Enforcer activity</h5>
      <p className={styles.subtitle}>Enforcer performance metrics.</p>

      {isLoading ? (
        <EnforcerActivitySkeleton />
      ) : isError ? (
        <EnforcerActivityError onRetry={onRetry} />
      ) : (
        <>
          <div className={styles.statsRow}>
            <div className={styles.statBox}>
              <span className={styles.statValue}>{averageWarning}</span>
              <span className={styles.statLabel}>AVG WARNINGS/DAY</span>
            </div>
            <div className={styles.statBox}>
              <span className={styles.statValue}>{averageTicket}</span>
              <span className={styles.statLabel}>AVG TICKETS/DAY</span>
            </div>
          </div>

          {/* <div className={styles.section}>
            <span className={styles.sectionTitle}>Enforcer Highlights</span>
            <div className={styles.highlightList}>
              {topEnforcers.map((highlight) => (
                <EnforcerHighlightItem key={highlight.enforcerId} name={highlight.enforcerName} note={highlight.} />
              ))}
            </div>
          </div> */}

          <div className={styles.section}>
            <span className={styles.sectionTitle}>Top Issuers this month</span>
            <div className={styles.issuerList}>
              {topEnforcers.length === 0 ? (
                <div className={styles.emptyIssuers}>
                  <div className={styles.emptyIssuersIconWrap}>
                    <Trophy size={20} className={styles.emptyIssuersIcon} />
                  </div>
                  <span className={styles.emptyIssuersTitle}>No activity yet</span>
                  <span className={styles.emptyIssuersText}>
                    Ticket rankings will appear here once enforcers start logging violations this month.
                  </span>
                </div>
              ) : (
                topEnforcers.map((issuer, index) => (
                  <div key={issuer.enforcerId}>
                    <TopIssuerRow rank={index + 1} name={issuer.enforcerName} count={issuer.totalTickets} />
                    {index < topEnforcers.length - 1 && <div className={styles.divider} />}
                  </div>
                ))
              )}
            </div>
          </div>
        </>
      )}
    </aside>
  );
};

export default EnforcerActivityPanel;