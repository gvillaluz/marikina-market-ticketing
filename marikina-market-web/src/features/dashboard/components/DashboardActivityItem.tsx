import type { DashboardActivity } from "@/api/types/dashboard.types";
import { formatDashboardTimestamp } from "../dashboard.utils";
import styles from "./DashboardActivityItem.module.css";

interface DashboardActivityItemProps {
  activity: DashboardActivity;
}

export default function DashboardActivityItem({
  activity,
}: DashboardActivityItemProps) {
  return (
    <article className={styles.item}>
      <span className={styles.category}>{activity.category}</span>
      <div className={styles.body}>
        <p className={styles.title}>{activity.title}</p>
        <p className={styles.description}>{activity.description}</p>
        <p className={styles.actor}>{activity.actorName?.trim() || "System"}</p>
      </div>
      <time className={styles.time} dateTime={activity.occurredAt}>
        {formatDashboardTimestamp(activity.occurredAt)}
      </time>
    </article>
  );
}
