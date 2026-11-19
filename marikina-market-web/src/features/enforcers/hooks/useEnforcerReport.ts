import { useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { useReactToPrint } from "react-to-print";
import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { downloadCsv, manilaDay } from "@/utils/tableExport";
import {
  ENFORCER_REPORT_COLUMNS,
  enforcerReportLines,
  reportPeriodPreset,
  validateReportPeriod,
  type ReportPeriod,
  type ReportPeriodPreset,
} from "../enforcerReport.utils";

const PAGE_STYLE = `
  @page { size: A4 landscape; margin: 10mm; }
`;

export function useEnforcerReport() {
  const today = manilaDay(new Date());
  const [period, setPeriod] = useState<ReportPeriod>(() =>
    reportPeriodPreset("month", today),
  );
  const paperRef = useRef<HTMLElement>(null);
  const validation = validateReportPeriod(period, today);
  const fileName = `Enforcer-report-${period.from}-to-${period.to}`;

  const query = useQuery({
    queryKey: ["enforcers", "report", period.from, period.to],
    queryFn: ({ signal }) =>
      enforcersApi.enforcerReport(period.from, period.to, signal),
    enabled: !validation,
    retry: false,
  });

  const print = useReactToPrint({
    contentRef: paperRef,
    documentTitle: fileName,
    pageStyle: PAGE_STYLE,
  });

  return {
    today,
    period,
    validation,
    report: validation ? undefined : query.data,
    loading: !validation && query.isFetching,
    error:
      !validation && query.isError
        ? getApiErrorMessage(
            query.error,
            "Couldn't load the enforcer report. Please try again.",
          )
        : "",
    paperRef,
    retry() {
      void query.refetch();
    },
    choosePreset(preset: ReportPeriodPreset) {
      setPeriod(reportPeriodPreset(preset, today));
    },
    changeFrom(from: string) {
      setPeriod((current) => ({ ...current, from }));
    },
    changeTo(to: string) {
      setPeriod((current) => ({ ...current, to }));
    },
    print() {
      print();
    },
    exportCsv() {
      if (!query.data) return;
      downloadCsv(
        `${fileName}.csv`,
        ENFORCER_REPORT_COLUMNS,
        enforcerReportLines(query.data),
      );
    },
  };
}

export type EnforcerReportModel = ReturnType<typeof useEnforcerReport>;
