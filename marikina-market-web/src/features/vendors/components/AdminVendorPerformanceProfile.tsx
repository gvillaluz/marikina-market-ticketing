import { Mail, Phone, UserRound } from "lucide-react";
import type { AdminVendorProfile } from "@/api/types/admin-vendor.types";
import Card from "@/components/ui/Card";
import { formatDate, formatDateTime } from "@/utils/formatters";
import styles from "./AdminVendorPerformanceProfile.module.css";

interface AdminVendorPerformanceProfileProps {
  profile: AdminVendorProfile;
}

function display(value: string | null | undefined): string {
  return value?.trim() || "Not provided";
}

export default function AdminVendorPerformanceProfile({
  profile,
}: AdminVendorPerformanceProfileProps) {
  const name = profile.name.trim() || "Registered owner";
  const lastViolation = profile.lastViolationIssuedAt;

  return (
    <Card className={`${styles.profileCard} motion-enter`}>
      <div className={styles.profileHeading}>
        <span className={styles.avatar} aria-hidden="true">
          {name
            .split(/\s+/)
            .slice(0, 2)
            .map((part) => part.charAt(0).toUpperCase())
            .join("")}
        </span>
        <div className={styles.nameWrap}>
          <h2>{name}</h2>
          <span className={styles.username}>
            Business Account Number: {display(profile.businessAccountNumber)}
          </span>
        </div>
      </div>

      <div className={styles.contactList}>
        <div className={styles.contactItem}>
          <span className={styles.contactIcon}><Phone size={13} /></span>
          <span>
            <small>CONTACT</small>
            {display(profile.phoneNumber)}
          </span>
        </div>
        <div className={styles.contactItem}>
          <span className={styles.contactIcon}><Mail size={13} /></span>
          <span>
            <small>EMAIL ADDRESS</small>
            {display(profile.email)}
          </span>
        </div>
        <div className={styles.contactItem}>
          <span className={styles.contactIcon}><UserRound size={13} /></span>
          <span>
            <small>BUSINESS CREATED</small>
            {formatDate(profile.createdAt)}
          </span>
        </div>
      </div>

      <div className={styles.profileFooter}>
        <div>
          <small>BUSINESS NAME</small>
          <strong>{profile.businessName}</strong>
        </div>
        <div>
          <small>LAST ACTIVITY</small>
          <strong>
            {lastViolation ? formatDateTime(lastViolation) : "No violations"}
          </strong>
        </div>
      </div>
    </Card>
  );
}
