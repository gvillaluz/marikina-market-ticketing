import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { enforcerActivityCsv } from "../enforcerReport.utils";
import { useReportDocument } from "./useReportDocument";

// The report of one enforcer. Nothing is asked of the server for an id that is not a positive whole number.
export function useEnforcerActivityReport(enforcerId: number) {
  return useReportDocument({
    queryKey: ["enforcers", enforcerId, "report"],
    enabled: Number.isInteger(enforcerId) && enforcerId > 0,
    load: (period, signal) =>
      enforcersApi.enforcerActivityReport(
        enforcerId,
        period.from,
        period.to,
        signal,
      ),
    fileName: `Enforcer-${enforcerId}-report`,
    toCsv: enforcerActivityCsv,
    failure: "Couldn't load this enforcer's report. Please try again.",
  });
}
