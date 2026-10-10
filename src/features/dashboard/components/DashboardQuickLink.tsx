import { ArrowUpRight } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { Link } from "react-router-dom";
import styles from "./DashboardQuickLink.module.css";

interface DashboardQuickLinkProps {
  label: string;
  description: string;
  to: string;
  icon: LucideIcon;
}

export default function DashboardQuickLink({
  label,
  description,
  to,
  icon: Icon,
}: DashboardQuickLinkProps) {
  return (
    <Link className={styles.link} to={to}>
      <span className={styles.icon} aria-hidden="true">
        <Icon size={18} />
      </span>
      <span className={styles.text}>
        <span className={styles.label}>{label}</span>
        <span className={styles.description}>{description}</span>
      </span>
      <ArrowUpRight className={styles.arrow} size={16} aria-hidden="true" />
    </Link>
  );
}
