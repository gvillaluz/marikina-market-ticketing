import { ChevronRight } from "lucide-react";
import { Link } from "react-router-dom";
import type { DashboardOverdueTicket } from "@/api/types/dashboard.types";
import { RecordBadge } from "@/components/ui/Records";
import { ROUTES } from "@/routes/routePaths";
import { formatControlNumberLabel } from "@/utils/formatters";
import { formatDaysOverdue } from "../dashboard.utils";
import styles from "./DashboardOverdueItem.module.css";

// Same wording as the Tickets table when a ticket kept no business details.
const UNAVAILABLE = "Historical business details unavailable.";

interface DashboardOverdueItemProps {
  ticket: DashboardOverdueTicket;
}

export default function DashboardOverdueItem({
  ticket,
}: DashboardOverdueItemProps) {
  return (
    <Link className={styles.item} to={ROUTES.ticketDetail(String(ticket.id))}>
      <span className={styles.text}>
        {ticket.vendorId === null ? (
          <RecordBadge value="Unregistered" />
        ) : (
          <span className={styles.business}>
            {ticket.businessName || UNAVAILABLE}
          </span>
        )}
        <span className={styles.controlNumber}>
          {formatControlNumberLabel(ticket.controlNumber)}
        </span>
      </span>
      <span className={styles.days}>
        {formatDaysOverdue(ticket.daysOverdue)}
      </span>
      <ChevronRight className={styles.arrow} size={16} aria-hidden="true" />
    </Link>
  );
}
