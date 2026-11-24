import { useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { recommendationsApi } from "@/api/endpoints/recommendations.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

const PAGE_SIZE = 10;

export function useDetectedViolations() {
  const [page, setPage] = useState(1);
  const offset = (page - 1) * PAGE_SIZE;
  const query = useQuery({
    queryKey: ["admin-recommendation-findings", offset],
    queryFn: () => recommendationsApi.getDetectedViolations(offset),
    placeholderData: keepPreviousData,
  });
  const total = query.data?.total ?? 0;

  return {
    rows: query.data?.items ?? [],
    total,
    page,
    totalPages: Math.max(page, Math.ceil(total / PAGE_SIZE)),
    changePage: setPage,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    errorMessage: getApiErrorMessage(
      query.error,
      "Couldn't load detected violations.",
    ),
    retry: () => void query.refetch(),
  };
}
