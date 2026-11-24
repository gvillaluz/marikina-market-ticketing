import { useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { recommendationsApi } from "@/api/endpoints/recommendations.api";
import useDebounce from "@/hooks/useDebounce";
import { ALL_STREETS } from "@/hooks/useMarketSectionOptions";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { ALL_VIOLATIONS } from "../recommendations.text";

const PAGE_SIZE = 10;

export type DetectedTypeFilter = "All types" | "Warning" | "Ticket";

export function useDetectedViolationsPage() {
  const [search, setSearch] = useState("");
  const [type, setType] = useState<DetectedTypeFilter>("All types");
  const [marketSection, setMarketSection] = useState(ALL_STREETS);
  const [categoryCode, setCategoryCode] = useState(ALL_VIOLATIONS);
  const [page, setPage] = useState(1);
  const [selectedTicketId, setSelectedTicketId] = useState(0);
  const debouncedSearch = useDebounce(search, 400);

  const params = {
    search: debouncedSearch.trim() || undefined,
    type: type === "All types" ? undefined : type,
    marketSectionId:
      marketSection === ALL_STREETS ? undefined : Number(marketSection),
    categoryCode: categoryCode === ALL_VIOLATIONS ? undefined : categoryCode,
  };
  const query = useQuery({
    queryKey: ["admin-recommendation-findings", params, page],
    queryFn: () =>
      recommendationsApi.getDetectedViolations({
        ...params,
        offset: (page - 1) * PAGE_SIZE,
      }),
    placeholderData: keepPreviousData,
  });
  const total = query.data?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const isFiltered =
    search.trim() !== "" ||
    type !== "All types" ||
    marketSection !== ALL_STREETS ||
    categoryCode !== ALL_VIOLATIONS;
  const onFirstPage =
    <T,>(change: (value: T) => void) =>
    (value: T) => {
      change(value);
      setPage(1);
    };

  return {
    rows: query.data?.items ?? [],
    total,
    totalPages,
    page,
    pageSize: PAGE_SIZE,
    search,
    type,
    marketSection,
    categoryCode,
    setSearch: onFirstPage(setSearch),
    setType: onFirstPage(setType),
    setMarketSection: onFirstPage(setMarketSection),
    setCategoryCode: onFirstPage(setCategoryCode),
    goToPage: (next: number) =>
      setPage(Math.min(Math.max(next, 1), totalPages)),
    emptyMessage: isFiltered
      ? "No detected violations match your search or filters."
      : "No violations were detected in the latest check.",
    isLoading: query.isPending || query.isPlaceholderData,
    isFetching: query.isFetching,
    isError: query.isError,
    errorMessage: getApiErrorMessage(
      query.error,
      "Couldn't load detected violations.",
    ),
    retry: () => void query.refetch(),
    selectedTicketId,
    openRecord: setSelectedTicketId,
    closeRecord: () => setSelectedTicketId(0),
  };
}
