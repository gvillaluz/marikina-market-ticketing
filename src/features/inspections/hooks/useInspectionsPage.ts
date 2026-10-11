import { useState } from "react";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { useInspectionFilters } from "./useInspectionFilters";
import { useInspections } from "./useInspections";
import { usePrintConfigForm } from "./usePrintConfigForm";

export function useInspectionsPage() {
  const { filters, setFilters, queryParams } = useInspectionFilters();
  const records = useInspections(queryParams);
  const [selectedTicketId, setSelectedTicketId] = useState(0);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const printConfig = usePrintConfigForm(["warning", "ticket"], () =>
    setIsExportOpen(false),
  );
  return {
    ...records,
    filters,
    setFilters,
    selectedTicketId,
    isExportOpen,
    printConfig,
    errorMessage: getApiErrorMessage(
      records.error,
      "Couldn't load inspection records. Please try again.",
    ),
    openTicket: setSelectedTicketId,
    closeTicket: () => setSelectedTicketId(0),
    openExport: () => setIsExportOpen(true),
    closeExport: () => setIsExportOpen(false),
    goToPage: (page: number) =>
      records.setPage(Math.min(Math.max(page, 1), records.totalPages)),
    print: () => window.print(),
  };
}
