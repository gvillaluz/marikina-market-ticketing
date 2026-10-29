import PageHeader from "@/components/ui/PageHeader";
import AdminVendorCompliancePanel from "../components/AdminVendorCompliancePanel";
import AdminCommunityServiceLogs from "../components/AdminCommunityServiceLogs";
import AdminVendorRegistry from "../components/AdminVendorRegistry";
import AdminCreateVendorModal from "../components/AdminCreateVendorModal";
import { useAdminCommunityServiceLogs } from "../hooks/useAdminCommunityServiceLogs";
import { useAdminVendorsPage } from "../hooks/useAdminVendorsPage";
import styles from "./AdminVendorsPage.module.css";

export default function AdminVendorsPage() {
  const { registry, compliance, businessForm } = useAdminVendorsPage();
  const communityServiceLogs = useAdminCommunityServiceLogs();

  return (
    <div className={styles.page}>
      <PageHeader
        title="Businesses"
        subtitle="Manage business licenses, registered owners and market locations."
      />

      <div className={styles.contentLayout}>
        <div className={styles.primaryColumn}>
          <AdminVendorRegistry {...registry} />
          <AdminCommunityServiceLogs {...communityServiceLogs} />
        </div>
        <AdminVendorCompliancePanel {...compliance} />
      </div>
      <AdminCreateVendorModal key={String(businessForm.businessId)} {...businessForm} />
    </div>
  );
}
