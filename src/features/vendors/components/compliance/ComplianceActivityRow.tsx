import { CircleAlert, ShieldAlert, Ticket, TriangleAlert } from "lucide-react";
import type { AdminVendorActivity } from "@/api/types/admin-vendor.types";
import { formatControlNumber } from "@/utils/formatters";
import styles from "../AdminVendorCompliancePanel.module.css";

function getViolationStyle(
  type: string | number | null | undefined,
  title?: string | null,
) {
  const normalized = `${type ?? ""} ${title ?? ""}`.toLowerCase();
  if (normalized.includes("ticket"))
    return { className: styles.ticketActivity, icon: Ticket };
  if (normalized.includes("warning"))
    return { className: styles.warningActivity, icon: TriangleAlert };
  if (normalized.includes("inspection"))
    return { className: styles.inspectionActivity, icon: ShieldAlert };
  return { className: styles.otherActivity, icon: CircleAlert };
}

function formatActivityTime(value: string) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  const seconds = Math.max(0, Math.floor((Date.now() - date.getTime()) / 1000));
  if (seconds < 60) return "just now";
  if (seconds < 3600) return `${Math.floor(seconds / 60)} min ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)} hr ago`;
  return `${Math.floor(seconds / 86400)} day${Math.floor(seconds / 86400) === 1 ? "" : "s"} ago`;
}

export default function ComplianceActivityRow({
  activity,
}: {
  activity: AdminVendorActivity;
}) {
  const violationStyle = getViolationStyle(
    activity.type,
    activity.activityTitle,
  );
  const ActivityIcon = violationStyle.icon;
  return (
    <div className={styles.activityRow}>
      <span className={`${styles.activityIcon} ${violationStyle.className}`}>
        <ActivityIcon size={15} strokeWidth={2.5} />
      </span>
      <div className={styles.activityDetails}>
        <p className={styles.activityText}>
          <strong>{activity.type}</strong> issued to{" "}
          <strong>{activity.vendorName}</strong>.
        </p>
        <span className={styles.activityVendor}>
          {activity.businessId}
          {activity.controlNumber
            ? ` · ${formatControlNumber(activity.controlNumber)}`
            : ""}
        </span>
      </div>
      <span className={styles.activityTime}>
        {formatActivityTime(activity.issuedAt)}
      </span>
    </div>
  );
}
