import { useNavigate } from "react-router-dom";
import Table from "@/components/ui/Table";
import { RecordBadge, RecordActions } from "@/components/ui/Records";
import type { TicketSummary } from "@/api/types/ticket.types";
import { formatDateTime, formatControlNumber } from "@/utils/formatters";
import styles from "./TicketList.module.css";
import { formatPenaltyType } from "../tickets.utils";

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
        {
          key: "controlNumber",
          header: "CTRL #",
          align: "left",
          render: (ticket) =>
            formatControlNumber(ticket.controlNumber).replace(/^CTRL #/, "#") ||
            "\u2014",
        },
        {
          key: "enforcer",
          header: "Enforcer",
          align: "left",
          render: (ticket) =>
            `${ticket.enforcerFirstName ?? ""} ${ticket.enforcerLastName ?? ""}`.trim() ||
            "\u2014",
        },
        {
          key: "vendor",
          header: "Vendor",
          align: "left",
          render: (ticket) =>
            `${ticket.vendorFirstName ?? ""} ${ticket.vendorLastName ?? ""}`.trim() ||
            "\u2014",
        },
        {
          key: "section",
          header: "Market section",
          align: "left",
          render: (ticket) => ticket.marketSectionName || "\u2014",
        },
        {
          key: "status",
          header: "Status",
          align: "center",
          render: (ticket) => <RecordBadge value={ticket.status || ""} />,
        },
        {
          key: "penaltyType",
          header: "Penalty",
          align: "center",
          render: (ticket) => formatPenaltyType(ticket.penaltyType),
        },
        {
          key: "severity",
          header: "Severity",
          align: "center",
          render: (ticket) => <RecordBadge value={ticket.severity || ""} />,
        },
        {
          key: "issuedAt",
          header: "Issued at",
          align: "left",
          render: (ticket) => formatDateTime(ticket.issuedAt),
        },
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
