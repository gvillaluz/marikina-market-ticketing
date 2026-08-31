import { ticketsApi } from "@/api/endpoints/tickets.api";
import { RecordStatus } from "@/api/types/common.types";
import { useMutation, useQueryClient } from "@tanstack/react-query";

interface UpdateStatusProps {
    newStatus: RecordStatus;
    version: number;
}

export function useUpdateStatus(ticketId: number) {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: ({ newStatus, version }: UpdateStatusProps) => {
            console.log(version)
            return ticketsApi.updateStatus({ticketId, newStatus, version})
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['ticket', 'detail', ticketId] })
        }
    });
}   