import type {
  AdminPendingTicketSettlement,
  AdminVendorComplianceOverview,
} from "@/api/types/admin-vendor.types";
import Card from "@/components/ui/Card";
import Pagination from "@/components/ui/Pagination";
import ComplianceActivityRow from "./compliance/ComplianceActivityRow";
import ComplianceOverviewSkeleton from "./compliance/ComplianceOverviewSkeleton";
import SettlementCard from "./compliance/SettlementCard";
import SettlementsSkeleton from "./compliance/SettlementsSkeleton";
import styles from "./AdminVendorCompliancePanel.module.css";

interface AdminVendorCompliancePanelProps {
  overview?: AdminVendorComplianceOverview;
  overviewIsLoading: boolean;
  overviewIsError: boolean;
  overviewErrorMessage: string;
  refetchOverview: () => void;
  settlements: AdminPendingTicketSettlement[];
  settlementPage: number;
  setSettlementPage: (page: number) => void;
  totalSettlementPages: number;
  settlementHasMore: boolean;
  settlementIsLoading: boolean;
  settlementIsError: boolean;
  settlementErrorMessage: string;
  refetchSettlements: () => void;
}

export default function AdminVendorCompliancePanel({
  overview,
  overviewIsLoading,
  overviewIsError,
  overviewErrorMessage,
  refetchOverview,
  settlements,
  settlementPage,
  setSettlementPage,
  totalSettlementPages,
  settlementHasMore,
  settlementIsLoading,
  settlementIsError,
  settlementErrorMessage,
  refetchSettlements,
}: AdminVendorCompliancePanelProps) {
  return (
    <Card className={styles.compliancePanel}>
      <div className={styles.panelHeading}>
        <h2>Market Compliance</h2>
        <p>Track market vendor activities.</p>
      </div>

      {overviewIsError ? (
        <div className={styles.panelError} role="alert">
          <span>{overviewErrorMessage}</span>
          <button type="button" onClick={refetchOverview}>
            Try again
          </button>
        </div>
      ) : overviewIsLoading ? (
        <ComplianceOverviewSkeleton />
      ) : (
        <>
          <div className={styles.summaryStats}>
            <Card className={styles.summaryStat}>
              <strong>
                {overview?.vendorsWithWarningsThisWeek ?? 0} VENDORS
              </strong>
              <span>WARNINGS THIS WEEK</span>
            </Card>
            <Card className={styles.summaryStat}>
              <strong>
                {overview?.vendorsWithTicketsThisWeek ?? 0} VENDORS
              </strong>
              <span>TICKETS THIS WEEK</span>
            </Card>
          </div>

          <section className={styles.panelSection}>
            <h3>New Activities</h3>
            {(overview?.activities ?? []).length === 0 ? (
              <p className={styles.panelEmpty}>No recent vendor activity.</p>
            ) : (
              <div className={styles.activityList}>
                {overview?.activities.map((activity) => (
                  <ComplianceActivityRow
                    key={activity.ticketId}
                    activity={activity}
                  />
                ))}
              </div>
            )}
          </section>
        </>
      )}

      <section
        className={`${styles.panelSection} ${styles.settlementsSection}`}
      >
        <h3>Pending Ticket Settlements</h3>
        {settlementIsError ? (
          <div className={styles.panelError} role="alert">
            <span>{settlementErrorMessage}</span>
            <button type="button" onClick={refetchSettlements}>
              Try again
            </button>
          </div>
        ) : settlementIsLoading ? (
          <SettlementsSkeleton />
        ) : (
          <>
            {settlements.length > 0 ? (
              <div className={styles.settlementList}>
                {settlements.map((settlement) => (
                  <SettlementCard
                    key={settlement.ticketId}
                    settlement={settlement}
                  />
                ))}
              </div>
            ) : (
              <p className={styles.panelEmpty}>
                {settlementHasMore
                  ? "No eligible settlements on this page."
                  : "No pending settlements."}
              </p>
            )}
            {(settlementHasMore || settlementPage > 1) && (
              <Pagination
                compact
                showSinglePage
                canGoNext={!settlementIsLoading && settlementHasMore}
                className={styles.settlementPagination}
                page={settlementPage}
                totalPages={totalSettlementPages}
                onChange={setSettlementPage}
              />
            )}
          </>
        )}
      </section>
    </Card>
  );
}
