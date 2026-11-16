import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { ApiRequestError } from "@/utils/apiErrors";
import { marketSectionApi } from "@/api/endpoints/marketSection.api";
import type { MarketSectionResponse } from "@/api/types/market-section.types";
import { marketSectionsListKey } from "@/hooks/useMarketSectionOptions";
import { exactMatchesFirst } from "@/utils/searchMatch";

const searchedValues = (section: MarketSectionResponse) => [section.name];

export function useMarketSections() {
  const [search, setSearch] = useState("");
  const query = useQuery({
    queryKey: marketSectionsListKey,
    queryFn: ({ signal }) => marketSectionApi.getAll(signal),
  });
  const sections = query.data ?? [];
  const searchTerm = search.trim().toLocaleLowerCase();
  const filteredSections = exactMatchesFirst(
    sections.filter((section) =>
      searchedValues(section).some((value) =>
        value.toLocaleLowerCase().includes(searchTerm),
      ),
    ),
    search,
    searchedValues,
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
    errorMessage: serverMessage || "Unable to load market streets. Please try again.",
    retry: () => { void query.refetch(); },
  };
}
