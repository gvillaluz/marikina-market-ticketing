import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { InspectionHistorySummary } from "@/api/types/enforcer.types";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";

const PAGE_SIZE = 10;

export function useFetchHistory(enforcerId: number) {
  const [page, setPage] = useState(1);

  useEffect(() => {
    setPage(1);
  }, [enforcerId]);

  const offset = (page - 1) * PAGE_SIZE;

  const query = useQuery({
    queryKey: ["history", enforcerId, "inspections"],
    queryFn: () => enforcersApi.enforcerHistory(enforcerId, { offset }),
    enabled: Number.isInteger(enforcerId) && enforcerId > 0,
  });

  const inspections: InspectionHistorySummary[] = query.data?.items ?? [];
  const total = query.data?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return {
    inspections,
    page,
    setPage,
    total,
    totalPages,
    pageSize: PAGE_SIZE,
    historyProcess: {
      isLoading: query.isLoading,
      isFetching: query.isFetching,
      isError: query.isError,
      error: query.error,
    },
  };
}
