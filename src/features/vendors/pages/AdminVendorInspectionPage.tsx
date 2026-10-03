import { Link, useLocation, useNavigate, useParams } from "react-router-dom";
import Button from "@/components/ui/Button";
import PageHeader from "@/components/ui/PageHeader";
import type { AdminVendorInspectionNavigationState } from "@/api/types/admin-vendor.types";
import { useAdminVendorProfile } from "../hooks/useAdminVendorProfile";
import { useAdminVendorInspectionPage } from "../hooks/useAdminVendorInspectionPage";
import AdminVendorComplianceScore from "../components/AdminVendorComplianceScore";
import AdminVendorInspectionHistory from "../components/AdminVendorInspectionHistory";
import AdminVendorPerformanceProfile from "../components/AdminVendorPerformanceProfile";
import AdminVendorPerformanceSkeleton from "../components/AdminVendorPerformanceSkeleton";
import AdminVendorPerformanceError from "../components/AdminVendorPerformanceError";
import { TicketModal } from "@/components/ui/TicketModal/TicketModal";
import styles from "./AdminVendorInspectionPage.module.css";

export default function AdminVendorInspectionPage() {
  const { vendorId: rawVendorId } = useParams<{ vendorId: string }>();
  const navigate = useNavigate();
  const location = useLocation();
  const vendorId = Number(rawVendorId);
  const navigationState =
    location.state as AdminVendorInspectionNavigationState | null;
  const {
    profile,
    score,
    isProfileLoading,
    isScoreLoading,
    isProfileError,
    isScoreError,
    profileErrorMessage,
    scoreErrorMessage,
    refetchProfile,
    refetchScore,
  } =
    useAdminVendorProfile(vendorId);
  const inspectionPage = useAdminVendorInspectionPage(vendorId);

  if (!Number.isInteger(vendorId) || vendorId < 1) {
    return (
      <div className={styles.errorPage}>
        <h2>Vendor record unavailable</h2>
        <p>This vendor record could not be found.</p>
        <Button onClick={() => navigate("/admin/vendors")}>
          Back to Vendors
        </Button>
      </div>
    );
  }

  const vendorName = profile?.name || navigationState?.vendorName || "Vendor";

  return (
    <div className={styles.page}>
      <nav className={styles.breadcrumb} aria-label="Breadcrumb">
        <Link to="/admin/vendors">Vendors</Link>
        <span aria-hidden="true">›</span>
        <span>{vendorName}</span>
      </nav>

      <PageHeader
        title="Vendor Performance Record"
        subtitle="Performance summary and inspection log for this vendor."
      />

      <section className={styles.summary} aria-label="Vendor performance summary">
        {isProfileError ? (
          <AdminVendorPerformanceError
            title="Profile unavailable"
            message={profileErrorMessage}
            onRetry={() => void refetchProfile()}
          />
        ) : isProfileLoading || !profile ? (
          <AdminVendorPerformanceSkeleton variant="profile" />
        ) : (
          <AdminVendorPerformanceProfile
            profile={profile}
          />
        )}
        {isScoreError ? (
          <AdminVendorPerformanceError
            title="Compliance score unavailable"
            message={scoreErrorMessage}
            onRetry={() => void refetchScore()}
          />
        ) : isScoreLoading || !score ? (
          <AdminVendorPerformanceSkeleton variant="score" />
        ) : (
          <AdminVendorComplianceScore score={score} />
        )}
      </section>

      <section className={styles.historySection}>
        <PageHeader
          title="Vendor Inspection History"
          subtitle="Inspection log for this vendor."
        />
        <AdminVendorInspectionHistory
          search={inspectionPage.search}
          onSearchChange={inspectionPage.setSearch}
          type={inspectionPage.type}
          onTypeChange={inspectionPage.setType}
          sortDirection={inspectionPage.sortDirection}
          onSortDirectionChange={inspectionPage.setSortDirection}
          page={inspectionPage.page}
          totalPages={inspectionPage.totalPages}
          onPageChange={inspectionPage.setPage}
          inspections={inspectionPage.inspections}
          total={inspectionPage.total}
          hasMore={inspectionPage.hasMore}
          isLoading={inspectionPage.isLoading}
          isFetching={inspectionPage.isFetching}
          isError={inspectionPage.isError}
          errorMessage={inspectionPage.errorMessage}
          onRetry={() => void inspectionPage.refetch()}
          onExport={inspectionPage.exportCurrentPage}
          onPrint={inspectionPage.print}
          onView={inspectionPage.setSelectedTicketId}
        />
      </section>
      {inspectionPage.selectedTicketId > 0 && (
        <TicketModal
          isOpen
          ticketId={inspectionPage.selectedTicketId}
          onClose={() => inspectionPage.setSelectedTicketId(0)}
        />
      )}
    </div>
  );
}
