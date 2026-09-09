import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { InspectionHistorySummary } from "@/api/types/enforcer.types";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";

const PAGE_SIZE = 10;

export function useFetchHistory(enforcerId: number) {
  const [page, setPage] = useState(1);

  useEffect(() => {
    setPage(1);
  }, []);

  const offset = (page - 1) * PAGE_SIZE;

  const query = useQuery({
    queryKey: ["history", enforcerId, "inspections"],
    queryFn: () => enforcersApi.enforcerHistory(enforcerId, { offset }),
  });

  const inspections: InspectionHistorySummary[] = query.data?.items ?? [];

  return {
    inspections,
    page,
    setPage,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    error: query.error,
  };
}
