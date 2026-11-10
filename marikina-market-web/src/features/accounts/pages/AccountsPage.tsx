import { Plus } from "lucide-react";
import PageHeader from "@/components/ui/PageHeader";
import { useAccounts } from "../hooks/useAccounts";
import AccountOverview from "../components/AccountOverview";
import AccountDirectory from "../components/AccountDirectory";
import styles from "./AccountsPage.module.css";
import { useAddStaffAccount } from "../hooks/useAddStaffAccount";
import AddStaffAccountModal from "../components/AddStaffAccountModal";
import CurrentAccountCard from "../components/CurrentAccountCard";
import { useManageAccount } from "../hooks/useManageAccount";

export default function AccountsPage() {
  const accounts = useAccounts();
  const staff = useAddStaffAccount();
  const manage = useManageAccount();
  return (
    <div className={styles.page}>
      <div>
        <p className={styles.eyebrow}>Identity &amp; Access</p>
        <PageHeader
          className={styles.header}
          title="Account Management"
          subtitle="Provision staff access and review all identities connected to the market system."
          actions={
            <button
              type="button"
              className={styles.addButton}
              disabled={!staff.canCreate}
              onClick={staff.show}
            >
              <Plus size={16} aria-hidden="true" />
              Add Staff Account
            </button>
          }
        />
      </div>
      <AccountOverview model={accounts} />
      {accounts.currentUser && (
        <CurrentAccountCard user={accounts.currentUser} />
      )}
      <AccountDirectory model={accounts} onManage={manage.show} />
      <AddStaffAccountModal model={staff} />
      <AddStaffAccountModal model={manage} />
    </div>
  );
}
