import { CircleAlert, ShieldAlert, Ticket, TriangleAlert } from "lucide-react";
import type {
  AdminPendingTicketSettlement,
  AdminVendorComplianceOverview,
  AdminVendorActivity,
} from "@/api/types/admin-vendor.types";
import Card from "@/components/ui/Card";
import Pagination from "@/components/ui/Pagination";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import { formatControlNumber, formatCurrency } from "@/utils/formatters";
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

function getTypeLabel(type: string | number | null | undefined): string {
  if (type == null) return "Other";
  return typeof type === "string"
    ? type.replace(/([a-z])([A-Z])/g, "$1 $2")
    : String(type);
}

function getActivityLabel(activity: AdminVendorActivity): string {
  return activity.activityTitle?.trim() || getTypeLabel(activity.type);
}

function getViolationStyle(
  type: string | number | null | undefined,
  activityTitle?: string | null,
) {
  const normalizedType = `${type ?? ""} ${activityTitle ?? ""}`.toLowerCase();
  if (normalizedType.includes("ticket")) {
    return { className: styles.ticketActivity, icon: Ticket };
  }
  if (normalizedType.includes("warning")) {
    return { className: styles.warningActivity, icon: TriangleAlert };
  }
  if (normalizedType.includes("inspection")) {
    return { className: styles.inspectionActivity, icon: ShieldAlert };
  }
  return { className: styles.otherActivity, icon: CircleAlert };
}

function formatActivityTime(value: string): string {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";

  const elapsedSeconds = Math.max(
    0,
    Math.floor((Date.now() - date.getTime()) / 1000),
  );
  if (elapsedSeconds < 60) return "just now";
  if (elapsedSeconds < 3600)
    return `${Math.floor(elapsedSeconds / 60)} min ago`;
  if (elapsedSeconds < 86400) {
    const hours = Math.floor(elapsedSeconds / 3600);
    return `${hours} hr${hours === 1 ? "" : "s"} ago`;
  }
  if (elapsedSeconds < 604800) {
    const days = Math.floor(elapsedSeconds / 86400);
    return `${days} day${days === 1 ? "" : "s"} ago`;
  }
  const weeks = Math.floor(elapsedSeconds / 604800);
  return `${weeks} wk${weeks === 1 ? "" : "s"} ago`;
}

function getSettlementLabel(settlement: AdminPendingTicketSettlement): string {
  const dueDate = new Date(settlement.dueDate);
  if (Number.isNaN(dueDate.getTime())) return "Pending";
  const remainingDays = Math.ceil(
    (dueDate.getTime() - Date.now()) / (24 * 60 * 60 * 1000),
  );
  if (remainingDays < 0) return "Overdue";
  if (remainingDays === 0) return "Due today";
  return `${remainingDays} day${remainingDays === 1 ? "" : "s"} left`;
}

function getSettlementDescription(
  settlement: AdminPendingTicketSettlement,
): string {
  const penaltyType = getTypeLabel(settlement.penaltyType);
  if (settlement.totalPaymentAmount != null) {
    return `${penaltyType} · ${formatCurrency(settlement.totalPaymentAmount)}`;
  }
  return penaltyType;
}

function ActivityRow({ activity }: { activity: AdminVendorActivity }) {
  const activityLabel = getActivityLabel(activity);
  const violationStyle = getViolationStyle(
    activity.type,
    activity.activityTitle,
  );
  const ActivityIcon = violationStyle.icon;

  return (
    <div className={styles.activityRow}>
      <span className={`${styles.activityIcon} ${violationStyle.className}`}>
        <ActivityIcon size={15} strokeWidth={2.5} />
      </span>
      <div className={styles.activityDetails}>
        <p className={styles.activityText}>
          <strong>{activity.type}</strong> issued to{" "}
          <strong>{activity.vendorName}</strong>.
        </p>
        <span className={styles.activityVendor}>
          {activity.businessId}
          {activity.controlNumber
            ? ` · ${formatControlNumber(activity.controlNumber)}`
            : ""}
        </span>
      </div>
      <span className={styles.activityTime}>
        {formatActivityTime(activity.issuedAt)}
      </span>
    </div>
  );
}

function SettlementCard({
  settlement,
}: {
  settlement: AdminPendingTicketSettlement;
}) {
  const dueLabel = getSettlementLabel(settlement);

  return (
    <Card
      className={`${styles.settlementCard} ${dueLabel === "Overdue" ? styles.overdueCard : ""}`}
    >
      <div className={styles.settlementTop}>
        <strong>
          {settlement.businessId} ·{" "}
          {formatControlNumber(
            settlement.controlNumber,
            `Ticket #${settlement.ticketId}`,
          )}
        </strong>
        <span className={styles.dueLabel}>{dueLabel}</span>
      </div>
      <span className={styles.settlementVendor}>{settlement.vendorName}</span>
      <span className={styles.settlementAmount}>
        {getSettlementDescription(settlement)}
      </span>
    </Card>
  );
}

function ComplianceOverviewSkeleton() {
  return (
    <>
      <div className={styles.summaryStats} aria-label="Loading market activity">
        {[0, 1].map((item) => (
          <Card className={`${styles.summaryStat} ${styles.skeletonStat}`} key={item}>
            <SkeletonBlock width="54%" height="19px" />
            <SkeletonBlock width="76%" height="10px" />
          </Card>
        ))}
      </div>
      <section className={styles.panelSection}>
        <h3>New Activities</h3>
        <div className={styles.activityList}>
          {[0, 1, 2].map((item) => (
            <div className={styles.skeletonActivity} key={item}>
              <SkeletonBlock width="32px" height="32px" radius="50%" />
              <div>
                <SkeletonBlock width="180px" height="11px" />
                <SkeletonBlock width="130px" height="9px" />
              </div>
              <SkeletonBlock width="48px" height="9px" />
            </div>
          ))}
        </div>
      </section>
    </>
  );
}

function SettlementsSkeleton() {
  return (
    <div className={styles.skeletonSettlements} aria-label="Loading settlements">
      {[0, 1, 2].map((item) => (
        <div className={styles.skeletonSettlement} key={item}>
          <div className={styles.skeletonSettlementTop}>
            <SkeletonBlock width="56%" height="12px" />
            <SkeletonBlock width="48px" height="9px" />
          </div>
          <SkeletonBlock width="68%" height="10px" />
          <SkeletonBlock width="43%" height="10px" />
        </div>
      ))}
    </div>
  );
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
                  <ActivityRow key={activity.ticketId} activity={activity} />
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
