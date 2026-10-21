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
import { useFetchProfile } from "../hooks/useFetchProfile";
import { useFetchPerformance } from "../hooks/useFetchPerformance";
import { useFetchHistory } from "../hooks/useFetchHistory";
import EnforcerProfileCardSkeleton from "../components/performance/EnforcerProfileCardSkeleton";
import PerformanceStatCardSkeleton from "../components/performance/PerformanceStatCardSkeleton";
import MonthlyInspectionsChartSkeleton from "../components/performance/MonthlyInspectionChartSkeleton";
import { TicketModal } from "@/components/ui/TicketModal/TicketModal";

const EnforcerPerformancePage: FC = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const enforcerId = Number(id) || 0;

  const { profile, profileProcess } = useFetchProfile(enforcerId);
  const { performance, performanceProcess } = useFetchPerformance(enforcerId);
  const { inspections, page, setPage, total, totalPages, historyProcess } =
    useFetchHistory(enforcerId);

  const [selectedTicketId, setSelectedTicketId] = useState<number>(0);

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Enforcer Performance Record"
        subtitle="Performance summary and inspection log for this enforcer."
      />

      <section className={styles.summary}>
        {profileProcess.isLoading || profileProcess.isFetching ? (
          <EnforcerProfileCardSkeleton />
        ) : (
          <EnforcerProfileCard profile={profile!} />
        )}

        {performanceProcess.isLoading || performanceProcess.isFetching ? (
          <>
            <div className={styles.stats}>
              <div className={styles.statsDrawer}>
                <PerformanceStatCardSkeleton />
                <PerformanceStatCardSkeleton />
              </div>
              <PerformanceStatCardSkeleton />
            </div>
            <MonthlyInspectionsChartSkeleton />
          </>
        ) : (
          <>
            <div className={styles.stats}>
              <div className={styles.statsDrawer}>
                <PerformanceStatCard
                  label="Total Inspections"
                  value={formatNumber(performance?.totalInspections || 0)}
                />
                <PerformanceStatCard
                  label="Resolution Rate"
                  value={`${performance?.resolutionRate}%`}
                />
              </div>
              <PerformanceStatCard
                label="Inspection Ratio"
                value={`${performance?.warningRatio}%`}
                subLabel="Warnings"
                progress={performance?.warningRatio}
                secondaryLabel={`${performance?.ticketRatio}% Tickets`}
              />
            </div>

            <MonthlyInspectionsChart
              inspections={performance?.monthlyInspections!}
            />
          </>
        )}
      </section>

      <section className={styles.history}>
        <PageHeader
          title="Enforcer Inspection History"
          subtitle="Performance summary and inspection log for this enforcer"
        />

        <div className={styles.recordsContainer}>
          <div className={styles.toolbar}>
            <h3 className={styles.activityTitle}>Activity Records</h3>
            <p className={styles.activitySubtitle}>
              Complete activity log for this enforcer.
            </p>
          </div>

          <EnforcerInspectionList
            records={inspections}
            onView={(recordId) => setSelectedTicketId(recordId)}
            loading={historyProcess.isLoading || historyProcess.isFetching}
          />

          {inspections.length !== 0 && (
            <div className={styles.footer}>
              <span className={styles.entries}>
                Showing {total === 0 ? 0 : (page - 1) * 9 + 1} to{" "}
                {Math.min(page * 9, total)} of {total} entries
              </span>

              <div className={styles.footerActions}>
                <button
                  className={styles.pageButton}
                  disabled={page <= 1}
                  onClick={() => goToPage(page - 1)}
                  aria-label="Previous page"
                >
                  ‹
                </button>
                {Array.from(
                  { length: Math.min(totalPages, 3) },
                  (_, index) => index + 1,
                ).map((p) => (
                  <button
                    key={p}
                    className={`${styles.pageButton} ${page === p ? styles.currentPage : ""}`}
                    onClick={() => goToPage(p)}
                    aria-label={`Go to page ${p}`}
                  >
                    {p}
                  </button>
                ))}
                {totalPages > 3 && <span className={styles.ellipsis}>...</span>}
                <button
                  className={styles.pageButton}
                  disabled={page >= totalPages}
                  onClick={() => goToPage(page + 1)}
                  aria-label="Next page"
                >
                  ›
                </button>
              </div>
            </div>
          )}
        </div>
        {selectedTicketId != 0 && (
          <TicketModal
            isOpen={selectedTicketId != 0}
            ticketId={selectedTicketId}
            onClose={() => setSelectedTicketId(0)}
          />
        )}
      </section>
    </div>
  );
};

export default EnforcerPerformancePage;
