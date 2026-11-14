import { useState } from "react";
import { ticketsApi } from "@/api/endpoints/tickets.api";
import { useTableExport } from "@/hooks/useTableExport";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { INSPECTION_COLUMNS } from "../inspections.utils";
import { useInspectionFilters } from "./useInspectionFilters";
import { useInspections } from "./useInspections";
import type { InspectionSummary } from "@/api/types/ticket.types";
import type { PrintConfigOptions } from "./usePrintConfigForm";

export function useInspectionsPage() {
  const { filters, setFilters, queryParams } = useInspectionFilters();
  const records = useInspections(queryParams);
  const [selectedTicketId, setSelectedTicketId] = useState(0);
  const [isExportOpen, setIsExportOpen] = useState(false);
  const closeExport = () => setIsExportOpen(false);
  const table = useTableExport({
    title: "Inspection records",
    fileName: "inspection-records.csv",
    columns: INSPECTION_COLUMNS,
    fetchPage: (offset) => ticketsApi.inspectionList({ ...queryParams, offset }),
  });
  const exportOptions: PrintConfigOptions<InspectionSummary> = {
    fileName: "inspection-records.csv",
    columns: INSPECTION_COLUMNS,
    recordTypes: ["Warning", "Ticket"],
    fetchPage: (offset, type) => ticketsApi.inspectionList({ offset, type }),
    onExported: closeExport,
  };
  return {
    ...records,
    filters,
    setFilters,
    selectedTicketId,
    isExportOpen,
    exportOptions,
    errorMessage: getApiErrorMessage(
      records.error,
      "Couldn't load inspection records. Please try again.",
    ),
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
