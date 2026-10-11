import { ticketsApi } from "@/api/endpoints/tickets.api";
import { RecordStatus } from "@/api/types/common.types";
import { useToast } from "@/components/ui/Toast/useToast";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { getApiErrorMessage } from "@/utils/apiErrors";

interface UpdateStatusProps {
  newStatus: RecordStatus;
  version: number;
}

export function useUpdateStatus(ticketId: number) {
  const queryClient = useQueryClient();
  const { showToast } = useToast();

  return useMutation({
    mutationFn: ({ newStatus, version }: UpdateStatusProps) => {
      return ticketsApi.updateStatus({ ticketId, newStatus, version });
    },
    onSuccess: async (data) => {
      await Promise.all([
        queryClient.invalidateQueries({
          queryKey: ["ticket", "detail", ticketId],
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
        title: "Status updated",
        description: `Ticket status changed to "${data.status}".`,
        variant: "success",
      });
    },
    onError: (error: Error) => {
      showToast({
        title: "Update failed",
        description: getApiErrorMessage(
          error,
          "Something went wrong while updating the ticket status.",
        ),
        variant: "error",
      });
    },
  });
}
