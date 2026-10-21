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

function roleLabel(role: string | number): string {
  if (typeof role !== "string") return "Vendor";
  return role.replace(/([a-z])([A-Z])/g, "$1 $2");
}

export default function AdminVendorPerformanceProfile({
  profile,
}: AdminVendorPerformanceProfileProps) {
  const name = profile.name.trim() || "Vendor";
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
            ID: {display(profile.username)}
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
            <small>ACCOUNT CREATED</small>
            {formatDate(profile.accountCreatedAt)}
          </span>
        </div>
      </div>

      <div className={styles.profileFooter}>
        <div>
          <small>ROLE</small>
          <strong>{roleLabel(profile.role)}</strong>
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
