import { useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { recommendationsApi } from "@/api/endpoints/recommendations.api";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { inListOrder, sectionToOpen } from "../recommendations.format";

export const recommendationsKey = ["admin-recommendations"];

// Below this width the card sits under the list (RecommendationsPage.module.css).
const STACKED_LAYOUT = "(max-width: 1099px)";

export function useRecommendationsPage() {
  const query = useQuery({
    queryKey: recommendationsKey,
    queryFn: () => recommendationsApi.getRecommendations(),
  });
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const detailRef = useRef<HTMLDivElement>(null);
  const sections = inListOrder(query.data?.recommendations ?? []);

  return {
    data: query.data,
    sections,
    selected: sectionToOpen(sections, selectedId),
    detailRef,
    openSection: (id: number) => {
      setSelectedId(id);
      if (window.matchMedia(STACKED_LAYOUT).matches)
        detailRef.current?.scrollIntoView({ block: "start" });
    },
    keepOpen: setSelectedId,
    isLoading: query.isLoading || query.isFetching,
    isError: query.isError,
    errorMessage: getApiErrorMessage(
      query.error,
      "Couldn't load recommended actions.",
    ),
    retry: () => void query.refetch(),
  };
}
