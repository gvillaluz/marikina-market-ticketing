import { useEffect, useMemo, useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import type {
  AdminVendorInspection,
  AdminVendorInspectionFilters,
} from "@/api/types/admin-vendor.types";
import { formatControlNumber, formatDateTime } from "@/utils/formatters";
import { useAdminVendorInspectionHistory } from "./useAdminVendorInspectionHistory";

const PAGE_SIZE = 10;
const SEARCH_DELAY_MS = 350;
export type VendorInspectionTypeFilter = "all" | "Warning" | "Ticket";

function exportInspectionRecords(rows: AdminVendorInspection[]) {
  const data = [
    ["Control Number", "Type", "Date & Time", "Ordinance(s)", "Enforcer"],
    ...rows.map((row) => [
      row.type === "Warning" ? "N/A" : formatControlNumber(row.controlNumber),
      String(row.type),
      formatDateTime(row.issuedAt),
      row.ordinanceNumbers.join(", "),
      row.enforcerName,
    ]),
  ];
  const csv = data
    .map((record) =>
      record.map((value) => `"${String(value).replace(/"/g, '""')}"`).join(","),
    )
    .join("\r\n");
  const fileUrl = URL.createObjectURL(
    new Blob([csv], { type: "text/csv;charset=utf-8" }),
  );
  const link = document.createElement("a");
  link.href = fileUrl;
  link.download = "vendor-inspection-history.csv";
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.setTimeout(() => URL.revokeObjectURL(fileUrl), 1000);
}

export function useAdminVendorInspectionPage(vendorId: number) {
  const [search, setSearch] = useState("");
  const [type, setType] = useState<VendorInspectionTypeFilter>("all");
  const [sortDirection, setSortDirection] =
    useState<AdminVendorInspectionFilters["sortDirection"]>("desc");
  const [page, setPage] = useState(1);
  const [selectedTicketId, setSelectedTicketId] = useState(0);
  const debouncedSearch = useDebounce(search, SEARCH_DELAY_MS);
  const offset = (page - 1) * PAGE_SIZE;

  useEffect(() => {
    setPage(1);
  }, [debouncedSearch, type, sortDirection, vendorId]);

  const filters = useMemo<AdminVendorInspectionFilters>(
    () => ({
      offset,
      search: debouncedSearch.trim() || undefined,
      ticketType: type === "all" ? undefined : type,
      sortDirection,
    }),
    [debouncedSearch, offset, sortDirection, type],
  );
  const query = useAdminVendorInspectionHistory(vendorId, filters);
  const totalPages =
    query.total === null
      ? page + (query.hasMore ? 1 : 0)
      : Math.max(1, Math.ceil(query.total / PAGE_SIZE));

  return {
    search,
    setSearch,
    type,
    setType,
    sortDirection,
    setSortDirection,
    page,
    setPage,
    totalPages,
    inspections: query.inspections,
    total: query.total,
    hasMore: query.hasMore,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    errorMessage: query.errorMessage,
    refetch: query.refetch,
    selectedTicketId,
    setSelectedTicketId,
    exportCurrentPage: () => exportInspectionRecords(query.inspections),
    print: () => window.print(),
  };
}
