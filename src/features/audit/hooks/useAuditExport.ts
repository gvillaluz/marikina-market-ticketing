import { useEffect, useRef, useState } from "react";
import { auditApi } from "@/api/endpoints/audit.api";
import type { AuditFilters, AuditLogSummary } from "@/api/types/audit.types";
import { useAuthStore } from "@/store/store";
import { useToast } from "@/components/ui/Toast/useToast";
import { isAdministrator } from "@/utils/roles";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import { validateAuditPage } from "../audit.validation";
import { AUDIT_PAGE_SIZE } from "../audit.constants";
import { auditCsv } from "../audit.utils";

export function useAuditExport() {
  const [isExporting, setIsExporting] = useState(false);
  const request = useRef<AbortController | null>(null);
  const { showToast } = useToast();
  useEffect(() => () => request.current?.abort(), []);

  async function exportLogs(filters: AuditFilters) {
    const user = useAuthStore.getState().user;
    if (request.current || !user || !isAdministrator(user.role)) return;
    const controller = new AbortController();
    request.current = controller;
    setIsExporting(true);
    try {
      const records: AuditLogSummary[] = [];
      const ids = new Set<number>();
      let offset = 0;
      let initialTotal: number | null = null;
      while (!controller.signal.aborted) {
        const page = validateAuditPage(
          await auditApi.list(filters, offset, controller.signal),
        );
        initialTotal ??= page.total;
        if (
          page.total !== initialTotal ||
          page.items.some((record) => ids.has(record.id))
        )
          throw new ApiRequestError(
            "Audit history changed during export. Please try again.",
          );
        for (const record of page.items) {
          ids.add(record.id);
          records.push(record);
        }
        if (!page.hasMore) break;
        offset += AUDIT_PAGE_SIZE;
        if (offset >= initialTotal) throw new ApiRequestError();
      }
      if (
        controller.signal.aborted ||
        useAuthStore.getState().user?.userId !== user.userId ||
        !isAdministrator(useAuthStore.getState().user?.role)
      )
        return;
      if (records.length !== initialTotal)
        throw new ApiRequestError(
          "Audit history changed during export. Please try again.",
        );
      const url = URL.createObjectURL(
        new Blob(["\ufeff", auditCsv(records)], {
          type: "text/csv;charset=utf-8",
        }),
      );
      const link = document.createElement("a");
      link.href = url;
      link.download = "audit-logs.csv";
      document.body.appendChild(link);
      try {
        link.click();
      } finally {
        link.remove();
        window.setTimeout(() => URL.revokeObjectURL(url), 1000);
      }
      showToast({ title: "Audit log exported", variant: "success" });
    } catch (failure: unknown) {
      if (!controller.signal.aborted)
        showToast({
          title: "Export failed",
          description: getApiErrorMessage(
            failure instanceof ApiRequestError ? failure : undefined,
            "Unable to export audit logs. Please try again.",
          ),
          variant: "error",
        });
    } finally {
      request.current = null;
      setIsExporting(false);
    }
  }
  return { isExporting, exportLogs };
}
