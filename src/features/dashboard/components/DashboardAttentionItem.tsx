import { ArrowUpRight } from "lucide-react";
import { Link } from "react-router-dom";
import type { DashboardAttentionItem as DashboardAttention } from "@/api/types/dashboard.types";
import { ROUTES } from "@/routes/routePaths";
import styles from "./DashboardAttentionItem.module.css";

interface DashboardAttentionItemProps {
  item: DashboardAttention;
}

export default function DashboardAttentionItem({
  item,
}: DashboardAttentionItemProps) {
  const to =
    item.type === "OpenTickets"
      ? ROUTES.tickets
      : ROUTES.adminVendorRegistrations;

  return (
    <Link className={styles.item} to={to}>
      <span className={styles.count}>{item.count.toLocaleString()}</span>
      <span className={styles.title}>{item.title}</span>
      <ArrowUpRight size={17} aria-hidden="true" />
    </Link>
  );
}
