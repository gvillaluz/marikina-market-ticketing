import { FC } from 'react';
import EnforcerHighlightItem from './EnforcerHighlightItem';
import TopIssuerRow from './TopIssuerRow';
import styles from './EnforcerActivityPanel.module.css';

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

const EnforcerActivityPanel: FC = () => {
  return (
    <aside className={styles.panel}>
      <h5 className={styles.title}>Enforcer activity</h5>
      <p className={styles.subtitle}>Enforcer performance metrics.</p>

      <div className={styles.statsRow}>
        <div className={styles.statBox}>
          <span className={styles.statValue}>{ACTIVITY_STATS.avgWarningsPerDay}</span>
          <span className={styles.statLabel}>AVG WARNINGS/DAY</span>
        </div>
        <div className={styles.statBox}>
          <span className={styles.statValue}>{ACTIVITY_STATS.avgTicketsPerDay}</span>
          <span className={styles.statLabel}>AVG TICKETS/DAY</span>
        </div>
      </div>

      <div className={styles.section}>
        <span className={styles.sectionTitle}>Enforcer Highlights</span>
        <div className={styles.highlightList}>
          {HIGHLIGHTS.map((highlight) => (
            <EnforcerHighlightItem key={highlight.id} name={highlight.name} note={highlight.note} />
          ))}
        </div>
      </div>

      <div className={styles.section}>
        <span className={styles.sectionTitle}>Top Issuers this month</span>
        <div className={styles.issuerList}>
          {TOP_ISSUERS.map((issuer, index) => (
            <>
                <TopIssuerRow key={issuer.id} rank={index + 1} name={issuer.name} count={issuer.count} />
                <div className={styles.divider}></div>
            </>
          ))}
        </div>
      </div>
    </aside>
  );
};

export default EnforcerActivityPanel;