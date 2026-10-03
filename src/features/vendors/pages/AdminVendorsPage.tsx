import PageHeader from "@/components/ui/PageHeader";
import AdminVendorCompliancePanel from "../components/AdminVendorCompliancePanel";
import AdminCommunityServiceLogs from "../components/AdminCommunityServiceLogs";
import AdminVendorRegistry from "../components/AdminVendorRegistry";
import { useAdminCommunityServiceLogs } from "../hooks/useAdminCommunityServiceLogs";
import { useAdminVendorsPage } from "../hooks/useAdminVendorsPage";
import styles from "./AdminVendorsPage.module.css";

export default function AdminVendorsPage() {
  const { registry, compliance } = useAdminVendorsPage();
  const communityServiceLogs = useAdminCommunityServiceLogs();

  return (
    <div className={styles.page}>
      <PageHeader
        title="Vendors"
        subtitle="Manage vendors and monitor market compliance."
      />

      <div className={styles.contentLayout}>
        <div className={styles.primaryColumn}>
          <AdminVendorRegistry {...registry} />
          <AdminCommunityServiceLogs {...communityServiceLogs} />
        </div>
        <AdminVendorCompliancePanel {...compliance} />
      </div>
    </div>
  );
}
