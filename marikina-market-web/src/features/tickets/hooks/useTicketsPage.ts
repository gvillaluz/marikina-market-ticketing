import { useState } from "react";
import { ticketsApi } from "@/api/endpoints/tickets.api";
import { useTableExport } from "@/hooks/useTableExport";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { TICKET_COLUMNS } from "../ticketColumns";
import { useTicketFilters } from "./useTicketFilters";
import { useTickets } from "./useTickets";
import { useTicketAnalytics } from "./useTicketAnalytics";
import type { TicketSummary } from "@/api/types/ticket.types";
import type { PrintConfigOptions } from "@/features/inspections";

export function useTicketsPage() {
  const { filters, setFilters, queryParams } = useTicketFilters();
  const records = useTickets(queryParams);
  const analytics = useTicketAnalytics();
  const [selectedTicketId, setSelectedTicketId] = useState(0);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const closeExport = () => setIsExportOpen(false);
  const table = useTableExport({
    title: "Ticket records",
    fileName: "ticket-records.csv",
    columns: TICKET_COLUMNS,
    fetchPage: (offset) => ticketsApi.ticketList({ ...queryParams, offset }),
  });
  const exportOptions: PrintConfigOptions<TicketSummary> = {
    fileName: "ticket-records.csv",
    columns: TICKET_COLUMNS,
    fetchPage: (offset) => ticketsApi.ticketList({ offset }),
    onExported: closeExport,
  };
  return {
    ...records,
    filters,
    setFilters,
    analytics,
    selectedTicketId,
    isExportOpen,
    exportOptions,
    errorMessage: records.isError
      ? getApiErrorMessage(
          records.error,
          "Couldn't load tickets. Please try again.",
        )
      : null,
    analyticsError: analytics.isError
      ? getApiErrorMessage(analytics.error, "Couldn't load the ticket summary.")
      : null,
    openTicket: setSelectedTicketId,
    closeTicket: () => setSelectedTicketId(0),
    openExport: () => setIsExportOpen(true),
    closeExport,
    goToPage: (page: number) =>
      records.setPage(Math.min(Math.max(page, 1), records.totalPages)),
    print: table.print,
    printPreparing: table.preparing === "print",
    printTable: table.printTable,
  };
}
