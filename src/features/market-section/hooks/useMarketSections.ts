import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { ApiRequestError } from "@/utils/apiErrors";
import { marketSectionApi } from "../api/marketSection.api";

export function useMarketSections() {
  const [search, setSearch] = useState("");
  const query = useQuery({
    queryKey: ["market_sections", "list"],
    queryFn: ({ signal }) => marketSectionApi.getAll(signal),
  });
  const sections = query.data ?? [];
  const searchTerm = search.trim().toLocaleLowerCase();
  const filteredSections = sections.filter(
    (section) =>
      section.name.toLocaleLowerCase().includes(searchTerm) ||
      section.description.toLocaleLowerCase().includes(searchTerm),
  );
  const serverMessage = query.error instanceof ApiRequestError
    ? query.error.serverMessage
    : undefined;

  return {
    search,
    setSearch,
    sections: filteredSections,
    total: sections.length,
    hasData: query.data !== undefined,
    isLoading: query.isPending,
    isFetching: query.isFetching,
    isError: query.isError,
    errorMessage: serverMessage || "Unable to load market sections. Please try again.",
    retry: () => { void query.refetch(); },
  };
}
