import { useRef, useState, type RefObject } from "react";
import { useQuery } from "@tanstack/react-query";
import { useReactToPrint } from "react-to-print";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { downloadCsvText, manilaDay } from "@/utils/tableExport";
import {
  reportPeriodPreset,
  validateReportPeriod,
  type ReportPeriod,
  type ReportPeriodPreset,
} from "../enforcerReport.utils";

const PAGE_STYLE = `
  @page { size: A4 landscape; margin: 10mm; }
`;

export interface ReportDocument<T> {
  today: string;
  period: ReportPeriod;
  validation: string;
  report: T | undefined;
  loading: boolean;
  error: string;
  paperRef: RefObject<HTMLElement>;
  retry(): void;
  choosePreset(preset: ReportPeriodPreset): void;
  changeFrom(from: string): void;
  changeTo(to: string): void;
  print(): void;
  exportCsv(): void;
}

interface ReportDocumentOptions<T> {
  queryKey: readonly unknown[];
  enabled?: boolean;
  load: (period: ReportPeriod, signal: AbortSignal) => Promise<T>;
  fileName: string;
  toCsv: (report: T) => string;
  failure: string;
}

// A report for a chosen period (this month to start with) that can be printed or saved as CSV.
export function useReportDocument<T>({
  queryKey,
  enabled = true,
  load,
  fileName,
  toCsv,
  failure,
}: ReportDocumentOptions<T>): ReportDocument<T> {
  const today = manilaDay(new Date());
  const [period, setPeriod] = useState<ReportPeriod>(() =>
    reportPeriodPreset("month", today),
  );
  const paperRef = useRef<HTMLElement>(null);
  const validation = validateReportPeriod(period, today);
  const ready = enabled && !validation;
  const name = `${fileName}-${period.from}-to-${period.to}`;

  const query = useQuery({
    queryKey: [...queryKey, period.from, period.to],
    queryFn: ({ signal }) => load(period, signal),
    enabled: ready,
    retry: false,
  });

  const print = useReactToPrint({
    contentRef: paperRef,
    documentTitle: name,
    pageStyle: PAGE_STYLE,
  });

  return {
    today,
    period,
    validation,
    report: ready ? query.data : undefined,
    loading: ready && query.isFetching,
    error:
      ready && query.isError ? getApiErrorMessage(query.error, failure) : "",
    paperRef,
    retry() {
      void query.refetch();
    },
    choosePreset(preset) {
      setPeriod(reportPeriodPreset(preset, today));
    },
    changeFrom(from) {
      setPeriod((current) => ({ ...current, from }));
    },
    changeTo(to) {
      setPeriod((current) => ({ ...current, to }));
    },
    print() {
      print();
    },
    exportCsv() {
      if (query.data) downloadCsvText(`${name}.csv`, toCsv(query.data));
    },
  };
}
