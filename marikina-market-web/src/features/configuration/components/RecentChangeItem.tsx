import { FC } from "react";
import { LucideIcon } from "lucide-react";
import styles from "./RecentChangeItem.module.css";

interface RecentChangeItemProps {
  icon: LucideIcon;
  title: string;
  detail: string;
  timestamp: string;
}

const RecentChangeItem: FC<RecentChangeItemProps> = ({
  icon: Icon,
  title,
  detail,
  timestamp,
}) => {
  return (
    <div className={styles.row}>
      <div className={styles.iconWrap}>
        <Icon size={14} strokeWidth={2} />
      </div>
      <div className={styles.text}>
        <span className={styles.title}>{title}</span>
        <span className={styles.detail}>{detail}</span>
      </div>
      <span className={styles.timestamp}>{timestamp}</span>
    </div>
  );
};

export default RecentChangeItem;
