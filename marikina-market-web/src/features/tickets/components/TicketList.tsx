import { useNavigate } from "react-router-dom";
import Table from "@/components/ui/Table";
import { RecordBadge, RecordActions } from "@/components/ui/Records";
import type { TicketSummary } from "@/api/types/ticket.types";
import { formatControlNumber } from "@/utils/formatters";
import styles from "./TicketList.module.css";
import { TICKET_COLUMNS } from "../ticketColumns";

const BADGE_COLUMNS = new Set(["status", "severity"]);
const CENTERED_COLUMNS = new Set(["status", "penaltyType", "severity"]);

interface TicketListProps {
  tickets: TicketSummary[];
  loading?: boolean;
  onView: (ticketId: number) => void;
}
export default function TicketList({
  tickets,
  loading,
  onView,
}: TicketListProps) {
  const navigate = useNavigate();
  return (
    <Table
      responsive
      className={styles.list}
      loading={loading}
      data={tickets}
      keyExtractor={(ticket) => ticket.id.toString()}
      emptyMessage="No tickets match your search or filters."
      columns={[
        ...TICKET_COLUMNS.map((column) => ({
          key: column.key,
          header: column.header,
          align: CENTERED_COLUMNS.has(column.key)
            ? ("center" as const)
            : ("left" as const),
          render: (ticket: TicketSummary) =>
            BADGE_COLUMNS.has(column.key) ? (
              <RecordBadge value={column.value(ticket)} />
            ) : (
              column.value(ticket)
            ),
        })),
        {
          key: "actions",
          header: "Actions",
          align: "center",
          render: (ticket) => (
            <RecordActions
              label={`ticket ${formatControlNumber(ticket.controlNumber)}`}
              onView={() => onView(ticket.id)}
              onChange={() => navigate(`/tickets/${ticket.id}`)}
            />
          ),
        },
      ]}
    />
  );
}
