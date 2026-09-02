import { ticketsApi } from "@/api/endpoints/tickets.api";
import { RecordStatus } from "@/api/types/common.types";
import { useToast } from "@/components/ui/Toast/useToast";
import { useMutation, useQueryClient } from "@tanstack/react-query";

interface UpdateStatusProps {
    newStatus: RecordStatus;
    version: number;
}

export function useUpdateStatus(ticketId: number) {
    const queryClient = useQueryClient();
    const { showToast } = useToast();

    return useMutation({
        mutationFn: ({ newStatus, version }: UpdateStatusProps) => {
            console.log(version)
            return ticketsApi.updateStatus({ticketId, newStatus, version})
        },
        onSuccess: (_data, variables) => {
            queryClient.invalidateQueries({ queryKey: ['ticket', 'detail', ticketId] })
            queryClient.invalidateQueries({ queryKey: ['tickets', 'analytics'] })

            showToast({
                title: 'Status updated',
                description: `Ticket status changed to "${variables.newStatus}".`,
                variant: 'success',
            });
        },
        onError: (error: Error) => {
            showToast({
                title: 'Update failed',
                description: error.message || 'Something went wrong while updating the ticket status.',
                variant: 'error',
            });
        },
    });
}   