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
  const [pagination, setPagination] = useState({ vendorId, page: 1 });
  const [selection, setSelection] = useState({ vendorId, ticketId: 0 });
  const page = pagination.vendorId === vendorId ? pagination.page : 1;
  const selectedTicketId =
    selection.vendorId === vendorId ? selection.ticketId : 0;
  const debouncedSearch = useDebounce(search.trim(), SEARCH_DELAY_MS);
  const waitingForSearch = search.trim() !== debouncedSearch;
  const offset = (page - 1) * PAGE_SIZE;
  useEffect(() => {
    setPagination({ vendorId, page: 1 });
    setSelection({ vendorId, ticketId: 0 });
  }, [vendorId]);

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
    setSearch(value: string) {
      setSearch(value);
      setPagination({ vendorId, page: 1 });
    },
    type,
    setType(value: VendorInspectionTypeFilter) {
      setType(value);
      setPagination({ vendorId, page: 1 });
    },
    sortDirection,
    setSortDirection(value: AdminVendorInspectionFilters["sortDirection"]) {
      setSortDirection(value);
      setPagination({ vendorId, page: 1 });
    },
    page,
    setPage(value: number) {
      if (
        query.isFetching ||
        waitingForSearch ||
        query.isError ||
        !Number.isSafeInteger(value) ||
        value < 1 ||
        (value > totalPages && value >= page) ||
        (value > page && !query.hasMore)
      )
        return;
      setPagination({ vendorId, page: Math.min(value, totalPages) });
    },
    totalPages,
    inspections: query.inspections,
    total: query.total,
    hasMore: query.hasMore,
    isLoading: query.isLoading || waitingForSearch,
    isFetching: query.isFetching || waitingForSearch,
    isError: query.isError,
    errorMessage: query.errorMessage,
    refetch: query.refetch,
    selectedTicketId,
    setSelectedTicketId(ticketId: number) {
      setSelection({ vendorId, ticketId });
    },
    exportCurrentPage: () => exportInspectionRecords(query.inspections),
    print: () => window.print(),
  };
}
