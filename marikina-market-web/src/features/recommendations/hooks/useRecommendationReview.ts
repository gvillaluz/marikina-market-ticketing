import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { recommendationsApi } from "@/api/endpoints/recommendations.api";
import type {
  RecommendationsResponse,
  SectionRecommendation,
} from "@/api/types/recommendations.types";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { withReview } from "../recommendations.format";
import { recommendationsKey } from "./useRecommendationsPage";

interface ReviewClick {
  id: number;
  action: "review" | "dismiss";
}

export function useRecommendationReview() {
  const client = useQueryClient();
  const [dismissTarget, setDismissTarget] =
    useState<SectionRecommendation | null>(null);

  const mutation = useMutation({
    mutationFn: ({ id, action }: ReviewClick) => recommendationsApi[action](id),
    onSuccess: (review, { id }) =>
      client.setQueryData<RecommendationsResponse>(
        recommendationsKey,
        (current) => current && withReview(current, id, review),
      ),
  });

  return {
    savingId: mutation.isPending ? (mutation.variables?.id ?? null) : null,
    errorMessage: mutation.isError
      ? getApiErrorMessage(
          mutation.error,
          "Couldn't save your decision. Please try again.",
        )
      : null,
    review: (id: number) => mutation.mutate({ id, action: "review" }),
    dismissTarget,
    askToDismiss: setDismissTarget,
    cancelDismiss: () => setDismissTarget(null),
    confirmDismiss: () => {
      if (!dismissTarget) return;
      mutation.mutate(
        { id: dismissTarget.id, action: "dismiss" },
        { onSettled: () => setDismissTarget(null) },
      );
    },
  };
}
