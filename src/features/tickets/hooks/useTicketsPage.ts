import { useState } from "react";
import { usePrintConfigForm } from "@/features/inspections";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { useTicketFilters } from "./useTicketFilters";
import { useTickets } from "./useTickets";
import { useTicketAnalytics } from "./useTicketAnalytics";

export function useTicketsPage() {
  const { filters, setFilters, queryParams } = useTicketFilters();
  const records = useTickets(queryParams);
  const analytics = useTicketAnalytics();
  const [selectedTicketId, setSelectedTicketId] = useState(0);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const printConfig = usePrintConfigForm(["ticket"], () =>
    setIsExportOpen(false),
  );
  return {
    ...records,
    filters,
    setFilters,
    analytics,
    selectedTicketId,
    isExportOpen,
    printConfig,
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
    closeExport: () => setIsExportOpen(false),
    goToPage: (page: number) =>
      records.setPage(Math.min(Math.max(page, 1), records.totalPages)),
    print: () => window.print(),
  };
}
