import { FC } from "react";
import EnforcerHighlightItem from "./EnforcerHighlightItem";
import TopIssuerRow from "./TopIssuerRow";
import styles from "./EnforcerActivityPanel.module.css";
import { TopIssuer } from "@/api/types/enforcer.types";
import EnforcerActivitySkeleton from "./EnforcerActivitySkeleton";
import EnforcerActivityError from "./EnforcerActivityError";
import { Trophy } from "lucide-react";

type EnforcerActivityProps = {
  averageTicket: number;
  averageWarning: number;
  topEnforcers: TopIssuer[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
};

const EnforcerActivityPanel: FC<EnforcerActivityProps> = ({
  averageTicket,
  averageWarning,
  topEnforcers,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}) => {
  return (
    <aside className={styles.panel}>
      <h5 className={styles.title}>Enforcer activity</h5>
      <p className={styles.subtitle}>Enforcer performance metrics.</p>

      {isLoading ? (
        <EnforcerActivitySkeleton />
      ) : isError ? (
        <EnforcerActivityError message={errorMessage} onRetry={onRetry} />
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

          <div className={styles.section}>
            <span className={styles.sectionTitle}>Top Issuers this month</span>
            <div className={styles.issuerList}>
              {topEnforcers.length === 0 ? (
                <div className={styles.emptyIssuers}>
                  <div className={styles.emptyIssuersIconWrap}>
                    <Trophy size={20} className={styles.emptyIssuersIcon} />
                  </div>
                  <span className={styles.emptyIssuersTitle}>
                    No activity yet
                  </span>
                  <span className={styles.emptyIssuersText}>
                    Ticket rankings will appear here once enforcers start
                    logging violations this month.
                  </span>
                </div>
              ) : (
                topEnforcers.map((issuer, index) => (
                  <div key={issuer.enforcerId}>
                    <TopIssuerRow
                      rank={index + 1}
                      name={issuer.enforcerName}
                      count={issuer.totalTickets}
                    />
                    {index < topEnforcers.length - 1 && (
                      <div className={styles.divider} />
                    )}
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
