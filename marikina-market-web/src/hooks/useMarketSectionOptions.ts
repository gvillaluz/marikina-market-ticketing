import { useQuery } from "@tanstack/react-query";
import { marketSectionApi } from "@/api/endpoints/marketSection.api";
import type { MarketSectionResponse } from "@/api/types/market-section.types";

// Shared with the settings page, so a street added or changed there shows up here at once.
export const marketSectionsListKey = ["market_sections", "list"] as const;

export const ALL_STREETS = "all";
export const LOADING_STREETS = "Loading streets…";

const toOption = (section: MarketSectionResponse) => ({
  value: String(section.id),
  label: section.name,
});

// Market streets from the server: filters offer every street (old records can still be
// found); the business form offers only streets that are turned on.
export function useMarketSectionOptions() {
  const query = useQuery({
    queryKey: marketSectionsListKey,
    queryFn: ({ signal }) => marketSectionApi.getAll(signal),
  });
  const sections = query.data ?? [];
  const activeOptions = sections.filter((section) => section.isActive).map(toOption);
  const filterOptions = [
    { value: ALL_STREETS, label: "All Streets" },
    ...sections.map(toOption),
  ];
  const nameOf = (id: string) =>
    sections.find((section) => String(section.id) === id)?.name;

  return {
    isLoading: query.isPending,
    activeOptions,
    filterOptions,
    nameOf,
    activeOptionsMessage: query.isError
      ? "Unable to load market streets. Please try again."
      : !query.isPending && activeOptions.length === 0
        ? "No active market streets. Add one in System Configuration."
        : undefined,
    filterLabel: (value: string) =>
      query.isPending
        ? LOADING_STREETS
        : value === ALL_STREETS
          ? "All Streets"
          : (nameOf(value) ?? "All Streets"),
  };
}
