import { ticketsApi } from "@/api/endpoints/tickets.api";
import type { ChangePenaltyRequest } from "@/api/types/ticket.types";
import { useToast } from "@/components/ui/Toast/useToast";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { penaltyLabel } from "../tickets.utils";

export function useChangePenalty(ticketId: number) {
  const queryClient = useQueryClient();
  const { showToast } = useToast();

  return useMutation({
    mutationFn: (request: ChangePenaltyRequest) =>
      ticketsApi.changePenalty({ ticketId, ...request }),
    onSuccess: async (data) => {
      await Promise.all([
        queryClient.invalidateQueries({
          queryKey: ["ticket", "detail", ticketId],
        }),
        queryClient.invalidateQueries({
          queryKey: ["ticket", "history", ticketId],
        }),
        queryClient.invalidateQueries({ queryKey: ["tickets"] }),
        queryClient.invalidateQueries({ queryKey: ["inspections"] }),
        queryClient.invalidateQueries({
          queryKey: ["admin-vendor-pending-settlements"],
        }),
        queryClient.invalidateQueries({
          queryKey: ["admin-community-service-logs"],
        }),
        queryClient.invalidateQueries({ queryKey: ["history"] }),
      ]);

      showToast({
        title: "Penalty changed",
        description: `Penalty changed to ${penaltyLabel(data.penaltyType)}.`,
        variant: "success",
      });
    },
    onError: (error: Error) => {
      showToast({
        title: "Change failed",
        description: getApiErrorMessage(
          error,
          "Something went wrong while changing the penalty.",
        ),
        variant: "error",
      });
    },
  });
}
