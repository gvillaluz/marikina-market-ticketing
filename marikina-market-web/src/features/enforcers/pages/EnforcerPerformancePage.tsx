import { FC, useState } from "react";
import { useParams } from "react-router-dom";
import PageHeader from "@/components/ui/PageHeader";
import { RecordsFooter, RecordsState } from "@/components/ui/Records";
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
  const enforcerId = Number(id);
  const isEnforcerId = Number.isInteger(enforcerId) && enforcerId > 0;

  const { profile, profileProcess } = useFetchProfile(enforcerId);
  const { performance, performanceProcess } = useFetchPerformance(enforcerId);
  const {
    inspections,
    page,
    setPage,
    pageSize,
    total,
    totalPages,
    historyProcess,
  } = useFetchHistory(enforcerId);

  const [selectedTicketId, setSelectedTicketId] = useState<number>(0);

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

  const header = (
    <PageHeader
      title="Enforcer Performance Record"
      subtitle="Performance summary and inspection log for this enforcer."
    />
  );

  if (!isEnforcerId) {
    return (
      <div className={styles.page}>
        {header}
        <RecordsState
          title="Enforcer not found"
          message="This link does not match an enforcer. Open the enforcer from the Enforcers list."
        />
      </div>
    );
  }

  return (
    <div className={styles.page}>
      {header}

      <section className={styles.summary}>
        {profileProcess.isLoading || profileProcess.isFetching ? (
          <EnforcerProfileCardSkeleton />
        ) : profile ? (
          <EnforcerProfileCard profile={profile} />
        ) : (
          <RecordsState
            title="Profile not loaded"
            message={profileProcess.errorMessage}
            onRetry={profileProcess.onRetry}
          />
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
        ) : performance ? (
          <>
            <div className={styles.stats}>
              <div className={styles.statsDrawer}>
                <PerformanceStatCard
                  label="Total Inspections"
                  value={formatNumber(performance.totalInspections)}
                />
                <PerformanceStatCard
                  label="Resolution Rate"
                  value={`${performance.resolutionRate}%`}
                />
              </div>
              <PerformanceStatCard
                label="Inspection Ratio"
                value={`${performance.warningRatio}%`}
                subLabel="Warnings"
                progress={performance.warningRatio}
                secondaryLabel={`${performance.ticketRatio}% Tickets`}
              />
            </div>

            <MonthlyInspectionsChart
              inspections={performance.monthlyInspections}
            />
          </>
        ) : (
          <div className={styles.summaryError}>
            <RecordsState
              title="Summary not loaded"
              message={performanceProcess.errorMessage}
              onRetry={performanceProcess.onRetry}
            />
          </div>
        )}
      </section>

      <section className={styles.history}>
        <PageHeader
          title="Enforcer Inspection History"
          subtitle="Every ticket and warning this enforcer has issued, newest first."
        />

        <div className={styles.recordsContainer}>
          <div className={styles.toolbar}>
            <h3 className={styles.activityTitle}>Activity Records</h3>
            <p className={styles.activitySubtitle}>
              Complete activity log for this enforcer.
            </p>
          </div>

          {historyProcess.isError && !historyProcess.isFetching ? (
            <RecordsState
              title="History not loaded"
              message={historyProcess.errorMessage}
              onRetry={historyProcess.onRetry}
            />
          ) : (
            <>
              <EnforcerInspectionList
                records={inspections}
                onView={(recordId) => setSelectedTicketId(recordId)}
                loading={historyProcess.isLoading || historyProcess.isFetching}
              />

              {inspections.length !== 0 && (
                <RecordsFooter
                  page={page}
                  pageSize={pageSize}
                  total={total}
                  totalPages={totalPages}
                  rowCount={inspections.length}
                  label="entries"
                  busy={historyProcess.isFetching}
                  onPageChange={goToPage}
                />
              )}
            </>
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
