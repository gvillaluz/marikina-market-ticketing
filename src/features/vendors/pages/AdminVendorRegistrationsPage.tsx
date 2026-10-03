import PageHeader from "@/components/ui/PageHeader";
import AdminVendorRegistrationStats from "../components/AdminVendorRegistrationStats";
import AdminVendorRegistrationTable from "../components/AdminVendorRegistrationTable";
import { useAdminVendorRegistrations } from "../hooks/useAdminVendorRegistrations";
import styles from "./AdminVendorRegistrationsPage.module.css";

export default function AdminVendorRegistrationsPage() {
  const registrations = useAdminVendorRegistrations();

  return (
    <div className={styles.page}>
      <div className={styles.breadcrumb}>VENDOR MANAGEMENT <span>›</span> ACCOUNT REGISTRANTS</div>
      <PageHeader
        title="Incoming Vendor Account Registrants"
        subtitle="Review new account requests, verify registration documents, assign reviewers, and resolve cases before vendor activation."
      />
      <AdminVendorRegistrationStats counts={registrations.counts} isLoading={registrations.isCountsLoading} />
      <AdminVendorRegistrationTable {...registrations} />
    </div>
  );
}
