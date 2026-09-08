import { FC } from "react";
import { ClipboardList, Target } from "lucide-react";
import styles from "./EnforcerStatCard.module.css";

interface EnforcerStatCardProps {
  label: string;
  value: string | number;
  icon: "clipboard" | "target";
}

const ICONS = { clipboard: ClipboardList, target: Target };

const EnforcerStatCard: FC<EnforcerStatCardProps> = ({
  label,
  value,
  icon,
}) => {
  const Icon = ICONS[icon];
  return (
    <div className={styles.card}>
      <div className={styles.iconWrap}>
        <Icon size={16} strokeWidth={2} />
      </div>
      <span className={styles.value}>{value}</span>
      <span className={styles.label}>{label}</span>
    </div>
  );
};

export default EnforcerStatCard;
