import { useMutation } from '@tanstack/react-query';
import { exportInspections } from '../../../api/endpoints/tickets.api';
import type { PrintConfigPayload, ExportResult } from '../../../api/types/ticket.types';

function isBlobResult(result: Blob | ExportResult): result is Blob {
  return result instanceof Blob;
}

export function usePrintExport() {
  const mutation = useMutation({
    mutationFn: (payload: PrintConfigPayload) => exportInspections(payload),
    onSuccess: (result) => {
      if (isBlobResult(result)) {
        const url = window.URL.createObjectURL(result);
        const link = document.createElement('a');
        link.href = url;
        link.download = `inspection-export-${Date.now()}.pdf`;
        document.body.appendChild(link);
        link.click();
        link.remove();
        window.URL.revokeObjectURL(url);
      } else {
        window.open(result.fileUrl, '_blank', 'noopener,noreferrer');
      }
    },
  });

  return {
    mutate: mutation.mutate,
    isPending: mutation.isPending,
    isError: mutation.isError,
    error: mutation.error,
    isSuccess: mutation.isSuccess,
  };
}
