import { ChevronRight, type LucideIcon } from "lucide-react";
import styles from "./RecoveryOption.module.css";

interface RecoveryOptionProps {
  icon: LucideIcon;
  title: string;
  description: string;
  onSelect: () => void;
  disabled?: boolean;
}

export default function RecoveryOption({
  icon: Icon,
  title,
  description,
  onSelect,
  disabled = false,
}: RecoveryOptionProps) {
  return (
    <button
      className={styles.option}
      type="button"
      onClick={onSelect}
      disabled={disabled}
    >
      <span className={styles.icon}>
        <Icon size={18} aria-hidden="true" />
      </span>
      <span className={styles.text}>
        <strong>{title}</strong>
        <span>{description}</span>
      </span>
      <ChevronRight className={styles.arrow} size={16} aria-hidden="true" />
    </button>
  );
}
