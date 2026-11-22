import { useNavigate } from "react-router-dom";
import BusinessCell from "@/components/ui/BusinessCell";
import SearchHighlight from "@/components/ui/SearchHighlight";
import Table from "@/components/ui/Table";
import {
  RecordBadge,
  RecordActions,
  RecordDateTime,
} from "@/components/ui/Records";
import type { TicketSummary } from "@/api/types/ticket.types";
import { formatControlNumber } from "@/utils/formatters";
import styles from "./TicketList.module.css";
import { TICKET_COLUMNS } from "../ticketColumns";

const BADGE_COLUMNS = new Set(["status", "severity"]);
const CENTERED_COLUMNS = new Set(["status", "penaltyType", "severity"]);
// The columns the ticket search looks at; the search text is highlighted in these.
const SEARCHED_COLUMNS = new Set([
  "controlNumber",
  "violator",
  "enforcer",
]);
// On screen the owner sits inside the Business column; Export and Print keep it separate.
const TABLE_COLUMNS = TICKET_COLUMNS.filter(
  (column) => column.key !== "registeredOwner",
);
const OWNER_COLUMN = TICKET_COLUMNS.find(
  (column) => column.key === "registeredOwner",
)!;

interface TicketListProps {
  tickets: TicketSummary[];
  search: string;
  loading?: boolean;
  onView: (ticketId: number) => void;
}
export default function TicketList({
  tickets,
  search,
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
        ...TABLE_COLUMNS.map((column) => ({
          key: column.key,
          header: column.key === "businessName" ? "Business" : column.header,
          align: CENTERED_COLUMNS.has(column.key)
            ? ("center" as const)
            : ("left" as const),
          render: (ticket: TicketSummary) =>
            column.key === "businessName" ? (
              <BusinessCell
                vendorId={ticket.vendorId}
                name={column.value(ticket)}
                owner={OWNER_COLUMN.value(ticket)}
                search={search}
              />
            ) : BADGE_COLUMNS.has(column.key) ? (
              <RecordBadge value={column.value(ticket)} />
            ) : column.key === "issuedAt" ? (
              <RecordDateTime value={ticket.issuedAt} />
            ) : SEARCHED_COLUMNS.has(column.key) ? (
              <SearchHighlight text={column.value(ticket)} search={search} />
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
