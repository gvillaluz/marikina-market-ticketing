import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { toCsv } from "@/utils/tableExport";
import {
  ENFORCER_REPORT_COLUMNS,
  enforcerReportLines,
} from "../enforcerReport.utils";
import { useReportDocument } from "./useReportDocument";

// The report of every enforcer.
export function useEnforcerReport() {
  return useReportDocument({
    queryKey: ["enforcers", "report"],
    load: (period, signal) =>
      enforcersApi.enforcerReport(period.from, period.to, signal),
    fileName: "Enforcer-report",
    toCsv: (report) =>
      toCsv(ENFORCER_REPORT_COLUMNS, enforcerReportLines(report)),
    failure: "Couldn't load the enforcer report. Please try again.",
  });
}
