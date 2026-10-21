import { FC } from "react";
import { LucideIcon } from "lucide-react";
import styles from "./StatCard.module.css";

interface StatCardProps {
  icon: LucideIcon;
  iconColor: string;
  iconBg: string;
  value: string | number;
  label: string;
  note: string;
}

const StatCard: FC<StatCardProps> = ({
  icon: Icon,
  iconColor,
  iconBg,
  value,
  label,
  note,
}) => {
  return (
    <div className={styles.card}>
      <div className={styles.header}>
        <div
          className={styles.iconWrap}
          style={{ background: iconBg, color: iconColor }}
        >
          <Icon size={20} strokeWidth={2} />
        </div>
        <div>
          <span className={styles.value}>{value}</span>
          <span className={styles.label}>{label}</span>
        </div>
      </div>
      <span className={styles.note}>{note}</span>
    </div>
  );
};

export default StatCard;
