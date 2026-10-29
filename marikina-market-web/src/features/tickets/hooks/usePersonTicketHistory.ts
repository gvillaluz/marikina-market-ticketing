import { useInfiniteQuery } from "@tanstack/react-query";
import { ticketsApi } from "@/api/endpoints/tickets.api";

export function usePersonTicketHistory(personId: number) {
  const query = useInfiniteQuery({
    queryKey: ["person", personId, "citation-history"],
    initialPageParam: 0,
    queryFn: ({ pageParam }) => ticketsApi.getPersonHistory(personId, pageParam),
    getNextPageParam: (last, pages) => last.hasMore
      ? pages.reduce((total, page) => total + page.items.length, 0) : undefined,
    enabled: Number.isSafeInteger(personId) && personId > 0,
  });
  return { ...query, items: query.data?.pages.flatMap(page => page.items) ?? [], total: query.data?.pages[0]?.total ?? 0 };
}
