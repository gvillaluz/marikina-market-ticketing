import { useMutation } from '@tanstack/react-query';
import { exportInspections } from '../../../api/endpoints/tickets.api';
import type { PrintConfigPayload, ExportResult } from '../../../api/types/ticket.types';
import type { ExportBlobResult } from '../../../api/endpoints/tickets.api';

export function usePrintExport() {
  const mutation = useMutation({
    mutationFn: (payload: PrintConfigPayload) => exportInspections(payload),
    onSuccess: (result) => {
      if ('blob' in result) {
        const url = window.URL.createObjectURL(result.blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = result.fileName;
        document.body.appendChild(link);
        link.click();
        link.remove();
        window.setTimeout(() => window.URL.revokeObjectURL(url), 1000);
      } else {
        const link = document.createElement('a');
        link.href = result.fileUrl;
        link.download = result.fileName;
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        document.body.appendChild(link);
        link.click();
        link.remove();
      }
    },
  });

  return {
    mutate: mutation.mutate,
    mutateAsync: mutation.mutateAsync,
    isPending: mutation.isPending,
    isError: mutation.isError,
    error: mutation.error,
    isSuccess: mutation.isSuccess,
  };
}
