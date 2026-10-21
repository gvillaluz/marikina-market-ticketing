import { ROUTES } from "@/routes/routePaths";
import Breadcrumb from "@/components/ui/Breadcrumb";
import styles from "./AdminVendorRegistrationsPage.module.css";
import { useState } from "react";
import { UserPlus } from "lucide-react";
import Button from "@/components/ui/Button";
import PageHeader from "@/components/ui/PageHeader";
import AdminCreateVendorModal from "../components/AdminCreateVendorModal";
import AdminVendorRegistrationStats from "../components/AdminVendorRegistrationStats";
import AdminVendorRegistrationTable from "../components/AdminVendorRegistrationTable";
import { useAdminVendorRegistrations } from "../hooks/useAdminVendorRegistrations";

export default function AdminVendorRegistrationsPage() {
  const registrations = useAdminVendorRegistrations();
  const [createOpen, setCreateOpen] = useState(false);

  return (
    <div className={styles.page}>
      <Breadcrumb
        items={[
          { label: "Vendor Management", to: ROUTES.adminVendors },
          { label: "Account Registrants" },
        ]}
      />
      <PageHeader
        className={styles.header}
        title="Incoming Vendor Account Registrants"
        subtitle="Review new account requests, verify registration documents, assign reviewers, and resolve cases before vendor activation."
        actions={
          <Button
            size="lg"
            icon={<UserPlus size={17} />}
            className={styles.createVendorButton}
            onClick={() => setCreateOpen(true)}
          >
            Create Vendor Account
          </Button>
        }
      />
      <AdminVendorRegistrationStats
        counts={registrations.counts}
        isLoading={registrations.isCountsLoading}
      />
      <AdminVendorRegistrationTable {...registrations} />
      <AdminCreateVendorModal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onSaved={registrations.refetch}
      />
    </div>
  );
}
