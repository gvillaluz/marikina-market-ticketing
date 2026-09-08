import { FC, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import PageHeader from "@/components/ui/PageHeader";
import Button from "@/components/ui/Button";
import { formatNumber } from "@/utils/formatters";
import EnforcerProfileCard from "../components/performance/EnforcerProfileCard";
import PerformanceStatCard from "../components/performance/PerformanceStatCard";
import MonthlyInspectionsChart from "../components/performance/MonthlyInspectionsChart";
import EnforcerInspectionList from "../components/performance/EnforcerInspectionList";
import styles from "./EnforcerPerformancePage.module.css";

/* ============================================================
   TEMPORARY STATIC DATA
   Remove this block and replace with real API / hooks later.
   ============================================================ */
const STATIC_PROFILE = {
  id: 12,
  employeeId: "EMP-2020-012",
  firstName: "Angelo",
  lastName: "Lee",
  fullName: "Lee, Angelo P.",
  initials: "LA",
  contactNumber: "+63 917 555 0142",
  email: "a.lee@marikinamarket.gov.ph",
  dateHired: "Jan 15, 2020",
  role: "Inspector",
  department: "Market Ops / FSSAM",
  status: "Active Duty" as const,
};

const STATIC_STATS = {
  totalInspections: 168,
  resolutionRate: 92,
  warningRatio: 69,
  ticketRatio: 31,
};

const STATIC_MONTHLY = [
  { month: "Jan", count: 15 },
  { month: "Feb", count: 22 },
  { month: "Mar", count: 18 },
  { month: "Apr", count: 28 },
  { month: "May", count: 31 },
  { month: "Jun", count: 24 },
  { month: "Jul", count: 19 },
  { month: "Aug", count: 27 },
  { month: "Sep", count: 33 },
  { month: "Oct", count: 29 },
  { month: "Nov", count: 21 },
  { month: "Dec", count: 16 },
];

const STATIC_INSPECTIONS = [
  {
    id: 4458,
    controlNumber: "TKT-4458",
    issuedAt: "2023-10-24T11:15:00",
    vendorFirstName: "Maria",
    vendorLastName: "Bautista",
    stallNo: "B-108",
    marketSectionName: "Dry Goods",
    type: "Ticket" as const,
    status: "Pending" as const,
  },
  {
    id: 1092,
    controlNumber: "WRN-1092",
    issuedAt: "2023-10-23T09:30:00",
    vendorFirstName: "Jose",
    vendorLastName: "Reyes",
    stallNo: "F-042",
    marketSectionName: "Fish & Seafood",
    type: "Ticket" as const,
    status: "Resolved" as const,
  },
  {
    id: 4450,
    controlNumber: "TKT-4450",
    issuedAt: "2023-10-22T08:00:00",
    vendorFirstName: "Elena",
    vendorLastName: "Cruz",
    stallNo: "M-015",
    marketSectionName: "Meat Section",
    type: "Ticket" as const,
    status: "Paid" as const,
  },
  {
    id: 1088,
    controlNumber: "WRN-1088",
    issuedAt: "2023-10-20T14:45:00",
    vendorFirstName: "Luis",
    vendorLastName: "Garcia",
    stallNo: "V-089",
    marketSectionName: "Vegetables",
    type: "Warning" as const,
    status: "Escalated" as const,
  },
];
/* ============================================================ */

const EnforcerPerformancePage: FC = () => {
  const { enforcerId } = useParams<{ enforcerId: string }>();
  const navigate = useNavigate();
  const id = Number(enforcerId) || 0;

  // Using static data for now
  const profile = STATIC_PROFILE;
  const stats = STATIC_STATS;
  const monthlyInspections = STATIC_MONTHLY;
  const inspections = STATIC_INSPECTIONS;

  const [selectedInspectionId, setSelectedInspectionId] = useState<number>(0);
  const [page, setPage] = useState(1);
  const pageSize = 4;
  const total = inspections.length;
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const paginatedRecords = inspections.slice(
    (page - 1) * pageSize,
    page * pageSize,
  );

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Enforcer Performance Record"
        subtitle="Performance summary and inspection log for this enforcer."
      />

      <div className={styles.statusRow}>
        <span className={`${styles.statusBadge} ${styles.active}`}>
          {profile.status}
        </span>
      </div>

      {/* Summary section */}
      <section className={styles.summary}>
        <EnforcerProfileCard profile={profile} />

        <div className={styles.stats}>
          <div className={styles.statsDrawer}>
            <PerformanceStatCard
              label="Total Inspections"
              value={formatNumber(stats.totalInspections)}
            />
            <PerformanceStatCard
              label="Resolution Rate"
              value={`${stats.resolutionRate}%`}
            />
          </div>
          <PerformanceStatCard
            label="Inspection Ratio"
            value={`${stats.warningRatio}%`}
            subLabel="Warnings"
            progress={stats.warningRatio}
            secondaryLabel={`${stats.ticketRatio}% Tickets`}
          />
        </div>

        <MonthlyInspectionsChart data={monthlyInspections} />
      </section>

      {/* Inspection history */}
      <section className={styles.history}>
        <div className={styles.sectionHeader}>
          <h2 className={styles.sectionTitle}>Enforcer Inspection History</h2>
          <p className={styles.sectionSubtitle}>
            Performance summary and inspection log for this enforcer.
          </p>
        </div>

        <div className={styles.recordsContainer}>
          <div className={styles.toolbar}>
            <div>
              <h3 className={styles.activityTitle}>Activity Records</h3>
              <p className={styles.activitySubtitle}>
                Complete activity log for this enforcer.
              </p>
            </div>
          </div>

          <EnforcerInspectionList
            records={paginatedRecords}
            onView={(recordId) => setSelectedInspectionId(recordId)}
          />

          {total > 0 && (
            <div className={styles.footer}>
              <span className={styles.entries}>
                Showing {total === 0 ? 0 : (page - 1) * pageSize + 1} to{" "}
                {Math.min(page * pageSize, total)} of {total} entries
              </span>

              <div className={styles.footerActions}>
                <button
                  className={styles.pageButton}
                  disabled={page <= 1}
                  onClick={() => goToPage(page - 1)}
                  aria-label="Previous page"
                >
                  Prev
                </button>

                {Array.from(
                  { length: Math.min(totalPages, 3) },
                  (_, i) => i + 1,
                ).map((p) => (
                  <button
                    key={p}
                    className={`${styles.pageButton} ${
                      page === p ? styles.currentPage : ""
                    }`}
                    onClick={() => goToPage(p)}
                    aria-label={`Go to page ${p}`}
                  >
                    {p}
                  </button>
                ))}

                {totalPages > 3 && <span className={styles.ellipsis}>…</span>}

                <button
                  className={styles.pageButton}
                  disabled={page >= totalPages}
                  onClick={() => goToPage(page + 1)}
                  aria-label="Next page"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* Bottom actions */}
      <div className={styles.bottomActions}>
        <Button
          variant="outline"
          onClick={() => {
            // TODO: open full ticket record
          }}
        >
          View Full Ticket Record
        </Button>
        <Button
          variant="primary"
          onClick={() => navigate(`/enforcers/${id}/edit`)}
        >
          Change Changes
        </Button>
      </div>
    </div>
  );
};

export default EnforcerPerformancePage;
