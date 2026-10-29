import { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import useDebounce from "@/hooks/useDebounce";
import type {
  AdminPendingTicketSettlement,
  AdminVendorSummary,
  AdminVendorSummaryFilters,
  ComplianceScoreRange,
} from "@/api/types/admin-vendor.types";
import { ROUTES } from "@/routes/routePaths";
import { useAdminVendors } from "./useAdminVendors";
import { useAdminVendorOverview } from "./useAdminVendorOverview";
import { useAdminPendingSettlements } from "./useAdminPendingSettlements";

const PAGE_SIZE = 10;
const SETTLEMENT_PAGE_SIZE = 10;

function isCommunityServiceSettlement(
  settlement: AdminPendingTicketSettlement,
): boolean {
  const penaltyType = String(settlement.penaltyType ?? "")
    .replace(/[\s_-]/g, "")
    .toLowerCase();
  return (
    penaltyType.includes("communityservice") ||
    settlement.communityServiceHours != null
  );
}

function exportVendorPage(vendors: AdminVendorSummary[]) {
  const rows = [
    [
      "Business Account Number",
      "Vendor Name",
      "Market Section",
      "Type",
      "Compliance Score",
      "Warnings",
      "Tickets",
    ],
    ...vendors.map((vendor) => [
      vendor.businessAccountNumber,
      vendor.vendorName,
      vendor.marketSectionName,
      vendor.type,
      `${vendor.complianceScore}%`,
      String(vendor.warningCount),
      String(vendor.ticketCount),
    ]),
  ];
  const csv = rows
    .map((row) =>
      row.map((value) => `"${String(value).replace(/"/g, '""')}"`).join(","),
    )
    .join("\r\n");
  const url = URL.createObjectURL(
    new Blob([csv], { type: "text/csv;charset=utf-8" }),
  );
  const link = document.createElement("a");
  link.href = url;
  link.download = "vendor-registry.csv";
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function useAdminVendorsPage() {
  const [businessOpen, setBusinessOpen] = useState(false);
  const [editingBusinessId, setEditingBusinessId] = useState<number | null>(null);
  const navigate = useNavigate();
  const [search, setSearch] = useState("");
  const [section, setSection] = useState("all");
  const [complianceScore, setComplianceScore] = useState<
    "all" | ComplianceScoreRange
  >("all");
  const [page, setPage] = useState(1);
  const [settlementPage, setSettlementPage] = useState(1);
  const debouncedSearch = useDebounce(search.trim(), 350);
  const waitingForSearch = search.trim() !== debouncedSearch;
  const offset = (page - 1) * PAGE_SIZE;
  const settlementOffset = (settlementPage - 1) * SETTLEMENT_PAGE_SIZE;

  const filters = useMemo<AdminVendorSummaryFilters>(
    () => ({
      offset,
      search: debouncedSearch.trim() || undefined,
      marketSectionId: section === "all" ? undefined : Number(section),
      complianceScore: complianceScore === "all" ? undefined : complianceScore,
    }),
    [debouncedSearch, offset, section, complianceScore],
  );
  const vendorQuery = useAdminVendors(filters);
  const overviewQuery = useAdminVendorOverview();
  const settlementQuery = useAdminPendingSettlements(settlementOffset);
  const settlements = settlementQuery.settlements.filter(
    (settlement) => !isCommunityServiceSettlement(settlement),
  );
  const settlementCount =
    settlementQuery.total ??
    settlementOffset +
    settlementQuery.settlements.length +
    (settlementQuery.hasMore ? 1 : 0);
  const totalSettlementPages = Math.max(
    settlementPage + (settlementQuery.hasMore ? 1 : 0),
    Math.ceil(settlementCount / SETTLEMENT_PAGE_SIZE),
  );

  return {
    businessForm: {
      open: businessOpen,
      businessId: editingBusinessId,
      onClose: () => setBusinessOpen(false),
      onSaved: async () => { await vendorQuery.refetch(); },
    },
    registry: {
      onCreateBusiness: () => { setEditingBusinessId(null); setBusinessOpen(true); },
      onEditBusiness: (vendor: AdminVendorSummary) => { setEditingBusinessId(vendor.vendorId); setBusinessOpen(true); },
      search,
      setSearch(value: string) {
        setSearch(value);
        setPage(1);
      },
      section,
      setSection(value: string) {
        setSection(value);
        setPage(1);
      },
      complianceScore,
      setComplianceScore(value: "all" | ComplianceScoreRange) {
        setComplianceScore(value);
        setPage(1);
      },
      page,
      setPage(value: number) {
        const totalPages =
          vendorQuery.total === null
            ? page + (vendorQuery.hasMore ? 1 : 0)
            : vendorQuery.totalPages;
        if (
          vendorQuery.isFetching ||
          waitingForSearch ||
          vendorQuery.isError ||
          !Number.isSafeInteger(value) ||
          value < 1 ||
          (value > totalPages && value >= page) ||
          (value > page && !vendorQuery.hasMore)
        )
          return;
        setPage(Math.min(value, totalPages));
      },
      vendors: vendorQuery.vendors,
      total: vendorQuery.total,
      hasMore: vendorQuery.hasMore,
      isLoading: vendorQuery.isLoading || waitingForSearch,
      isFetching: vendorQuery.isFetching || waitingForSearch,
      isError: vendorQuery.isError,
      errorMessage: vendorQuery.errorMessage,
      refetch: vendorQuery.refetch,
      exportCurrentPage: () => exportVendorPage(vendorQuery.vendors),
      print: () => window.print(),
      onViewInspections: (vendor: AdminVendorSummary) =>
        navigate(ROUTES.adminVendorInspections(String(vendor.vendorId)), {
          state: {
            vendorName: vendor.vendorName,
            businessAccountNumber: vendor.businessAccountNumber,
          },
        }),
    },
    compliance: {
      overview: overviewQuery.overview,
      overviewIsLoading: overviewQuery.isLoading,
      overviewIsError: overviewQuery.isError,
      overviewErrorMessage: overviewQuery.errorMessage,
      refetchOverview: overviewQuery.refetch,
      settlements,
      settlementPage,
      setSettlementPage,
      totalSettlementPages,
      settlementHasMore: settlementQuery.hasMore,
      settlementIsLoading: settlementQuery.isLoading,
      settlementIsError: settlementQuery.isError,
      settlementErrorMessage: settlementQuery.errorMessage,
      refetchSettlements: settlementQuery.refetch,
    },
  };
}
