import { useEffect, useMemo, useState } from "react";
import useDebounce from "@/hooks/useDebounce";
import type { AdminVendorInspectionFilters } from "@/api/types/admin-vendor.types";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import { useTableExport } from "@/hooks/useTableExport";
import { BUSINESS_HISTORY_COLUMNS } from "../businessTableColumns";
import { useAdminVendorInspectionHistory } from "./useAdminVendorInspectionHistory";

const PAGE_SIZE = 10;
const SEARCH_DELAY_MS = 350;
export type VendorInspectionTypeFilter = "all" | "Warning" | "Ticket";

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
  const table = useTableExport({
    title: "Business inspection history",
    fileName: "vendor-inspection-history.csv",
    columns: BUSINESS_HISTORY_COLUMNS,
    fetchPage: (offset) =>
      adminVendorsApi.getInspectionHistory(vendorId, { ...filters, offset }),
  });
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
    exportFile: table.exportFile,
    print: table.print,
    preparing: table.preparing,
    printTable: table.printTable,
  };
}
