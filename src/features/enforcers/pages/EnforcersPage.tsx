import { FC, useState } from "react";
import PageHeader from "@/components/ui/PageHeader";
import { Dropdown } from "@/components/ui/Dropdown";
import { Search, Users } from "lucide-react";
import EnforcerCard from "../components/EnforcerCard";
import EnforcerActivityPanel from "../components/EnforcerActivityPanel";
import styles from "./EnforcersPage.module.css";
import { useEnforcerFilter } from "../hooks/useEnforcerFilter";
import { useFetchEnforcers } from "../hooks/useFetchEnforcers";
import { AccountStatus } from "@/api/types/common.types";
import { useFetchActivity } from "../hooks/useFetchActivity";
import EnforcerListError from "../components/EnforcerListError";
import EnforcerCardSkeleton from "../components/EnforcerCardSkeleton";
import { useNavigate } from "react-router-dom";

const STATUS_FILTERS = ["Active", "Inactive"];

const EnforcersPage: FC = () => {
  const navigate = useNavigate();
  const { filters, setFilters, sortOptions, queryParams } = useEnforcerFilter();
  const { enforcers, total, totalPages, page, setPage, fetchProcess } =
    useFetchEnforcers(queryParams);
  const { averageWarning, averageTicket, topEnforcers, activityProcess } =
    useFetchActivity();

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

  return (
    <div>
      <PageHeader
        title="Enforcer Performance Records"
        subtitle="Monitor duty records for market enforcers."
      />

      <div className={styles.layout}>
        <section className={styles.recordsContainer}>
          <div className={styles.toolbar}>
            <div className={styles.searchWrapper}>
              <Search
                className={styles.searchIcon}
                size={14}
                strokeWidth={1.8}
                aria-hidden="true"
              />
              <input
                className={styles.searchInput}
                placeholder="Search by name or ID…"
                value={filters.search}
                onChange={(e) => setFilters.setSearch(e.target.value)}
              />
            </div>

            <div className={styles.filterGroup}>
              <Dropdown
                ariaLabel="Filter by Status"
                triggerLabel={`Filter by Status`}
                value={filters.statusFilter}
                onChange={(value) =>
                  setFilters.setStatusFilter(value as AccountStatus)
                }
                options={STATUS_FILTERS.map((filter) => ({
                  value: filter,
                  label: filter,
                }))}
              />
              <Dropdown
                ariaLabel="Sort"
                triggerLabel={filters.sort}
                value={filters.sort}
                onChange={(value) => setFilters.setSort(value)}
                options={Object.keys(sortOptions).map((label) => ({
                  value: label,
                  label,
                }))}
              />
            </div>
          </div>

          <div className={styles.grid}>
            {fetchProcess.isLoading ? (
              Array.from({ length: 2 }).map((_, i) => (
                <EnforcerCardSkeleton key={i} />
              ))
            ) : fetchProcess.isError ? (
              <EnforcerListError onRetry={fetchProcess.onRetry} />
            ) : enforcers.length === 0 ? (
              <div className={styles.emptyState}>
                <div className={styles.emptyStateIconWrap}>
                  <Users size={22} className={styles.emptyStateIcon} />
                </div>
                <span className={styles.emptyStateTitle}>
                  No enforcers found
                </span>
                <span className={styles.emptyStateText}>
                  No enforcers match your current filters. Try adjusting your
                  search or status filter.
                </span>
              </div>
            ) : (
              enforcers.map((enforcer) => (
                <EnforcerCard
                  key={enforcer.enforcerId}
                  name={`${enforcer.lastName}, ${enforcer.firstName}`}
                  initials={`${enforcer.lastName[0].toUpperCase()}${enforcer.firstName[0].toUpperCase()}`}
                  profileUrl={enforcer.profileUrl}
                  badgeNo={enforcer.username}
                  status={enforcer.status}
                  warnings={enforcer.warningViolationCount}
                  tickets={enforcer.ticketViolationCount}
                  onViewInspections={() => {
                    navigate(`/enforcer/performance/${enforcer.enforcerId}`);
                  }}
                />
              ))
            )}
          </div>

          {enforcers.length !== 0 && (
            <div className={styles.footer}>
              <span className={styles.entries}>
                Showing {total === 0 ? 0 : (page - 1) * 9 + 1} to{" "}
                {Math.min(page * 9, total)} of {total} entries
              </span>

              <div className={styles.pagination}>
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
        </section>

        <EnforcerActivityPanel
          averageTicket={averageTicket ?? 0.0}
          averageWarning={averageWarning ?? 0.0}
          topEnforcers={topEnforcers ?? []}
          isLoading={activityProcess.isLoading && activityProcess.isFetching}
          isError={activityProcess.isError}
          onRetry={activityProcess.onRetry}
        />
      </div>
    </div>
  );
};

export default EnforcersPage;
