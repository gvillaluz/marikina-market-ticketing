import { useState } from "react";
import { UserPlus } from "lucide-react";
import Button from "@/components/ui/Button";
import PageHeader from "@/components/ui/PageHeader";
import AdminCreateVendorModal from "../components/AdminCreateVendorModal";
import AdminVendorRegistrationStats from "../components/AdminVendorRegistrationStats";
import AdminVendorRegistrationTable from "../components/AdminVendorRegistrationTable";
import { useAdminVendorRegistrations } from "../hooks/useAdminVendorRegistrations";
import styles from "./AdminVendorRegistrationsPage.module.css";

export default function AdminVendorRegistrationsPage() {
  const registrations = useAdminVendorRegistrations();
  const [createOpen, setCreateOpen] = useState(false);

  return (
    <div className={styles.page}>
      <div className={styles.breadcrumb}>
        VENDOR MANAGEMENT <span>›</span> ACCOUNT REGISTRANTS
      </div>
      <PageHeader
        title="Incoming Vendor Account Registrants"
        subtitle="Review new account requests, verify registration documents, assign reviewers, and resolve cases before vendor activation."
        actions={
          <Button
            size="lg"
            icon={<UserPlus size={17} />}
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
