import { ClipboardList, CircleCheck, CircleX, FileWarning } from "lucide-react";
import type { VendorRegistrationStatusCounts } from "@/api/types/admin-vendor.types";
import styles from "./AdminVendorRegistrationStats.module.css";

interface Props {
  counts?: VendorRegistrationStatusCounts;
  isLoading: boolean;
}

const CARDS = [
  { key: "pendingReview", label: "Pending Review", icon: ClipboardList, tone: "pending" },
  { key: "needsInformation", label: "Needs Information", icon: FileWarning, tone: "info" },
  { key: "approved", label: "Approved", icon: CircleCheck, tone: "approved" },
  { key: "rejected", label: "Rejected", icon: CircleX, tone: "rejected" },
] as const;

export default function AdminVendorRegistrationStats({ counts, isLoading }: Props) {
  return (
    <div className={styles.grid}>
      {CARDS.map(({ key, label, icon: Icon, tone }) => (
        <div className={`${styles.card} ${styles[tone]}`} key={key}>
          <div className={styles.cardTop}>
            <span className={styles.icon}><Icon size={18} /></span>
            <span className={styles.value}>{isLoading ? "—" : counts?.[key] ?? 0}</span>
          </div>
          <div className={styles.label}>{label}</div>
          <div className={styles.helper}>
            {key === "pendingReview" ? "Awaiting initial review" :
              key === "needsInformation" ? "Follow-up required" :
                key === "approved" ? "Ready for activation" : "Not approved"}
          </div>
        </div>
      ))}
    </div>
  );
}
