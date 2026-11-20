import type { RefObject } from "react";
import type { EnforcerActivityReport } from "@/api/types/enforcer.types";
import {
  formatManilaDate,
  formatReportPeriod,
  violationTypeLabel,
} from "../../enforcerReport.utils";
import EnforcerReportPaperFrame from "./EnforcerReportPaperFrame";
import EnforcerReportTable from "./EnforcerReportTable";
import EnforcerReportHeading from "./EnforcerReportHeading";
import EnforcerSummaryTiles from "./EnforcerSummaryTiles";
import EnforcerPenaltyRow from "./EnforcerPenaltyRow";
import EnforcerCountRow from "./EnforcerCountRow";
import EnforcerDayChart from "./EnforcerDayChart";
import styles from "./EnforcerActivityPaper.module.css";

const SHARE_COLUMNS = ["Warnings", "Tickets", "Total", "Share of records"];

// One enforcer's report: summary tiles, then penalty kinds, violation types, streets and days.
export default function EnforcerActivityPaper({
  report,
  paperRef,
}: {
  report: EnforcerActivityReport;
  paperRef: RefObject<HTMLElement>;
}) {
  const { enforcer } = report;
  const totalRecords = enforcer.totalRecords;
  return (
    <EnforcerReportPaperFrame
      paperRef={paperRef}
      title="Enforcer Activity Report"
      meta={[
        { term: "Enforcer", value: `${enforcer.lastName}, ${enforcer.firstName}` },
        { term: "Username", value: enforcer.username },
        { term: "Reporting period", value: formatReportPeriod(report.dateRange) },
      ]}
    >
      <EnforcerSummaryTiles row={enforcer} />
      {totalRecords === 0 ? (
        <p className={styles.empty}>
          No warnings or tickets were recorded in this period.
        </p>
      ) : (
        <>
          {report.penaltyKinds.length > 0 && (
            <EnforcerReportTable
              heading="Penalty kind"
              label="Tickets by penalty kind"
              columns={[
                "Penalty kind",
                "Tickets",
                "Settled tickets",
                "Open tickets",
                "Fines charged",
              ]}
            >
              {report.penaltyKinds.map((kind) => (
                <EnforcerPenaltyRow key={kind.penaltyType ?? "none"} kind={kind} />
              ))}
            </EnforcerReportTable>
          )}
          <div className={styles.group}>
            <EnforcerReportTable
              heading="Violation type"
              label="Records by violation type"
              columns={["Violation type", ...SHARE_COLUMNS]}
            >
              {report.violationTypes.map((type) => (
                <EnforcerCountRow
                  key={type.category ?? "none"}
                  label={violationTypeLabel(type.category)}
                  counts={type}
                  totalRecords={totalRecords}
                  muted={type.category === null}
                />
              ))}
            </EnforcerReportTable>
            <p className={styles.note}>
              A record with more than one violation type is counted under each.
            </p>
          </div>
          <EnforcerReportTable
            heading="Market street"
            label="Records by market street"
            columns={["Market street", ...SHARE_COLUMNS]}
          >
            {report.marketStreets.map((street) => (
              <EnforcerCountRow
                key={street.marketSectionId}
                label={street.marketSectionName}
                counts={street}
                totalRecords={totalRecords}
              />
            ))}
          </EnforcerReportTable>
          <div className={styles.group}>
            <EnforcerReportHeading>Records per day</EnforcerReportHeading>
            <EnforcerDayChart days={report.days} period={report.dateRange} />
            <EnforcerReportTable
              label="Records per day"
              columns={["Date", "Warnings", "Tickets", "Total"]}
            >
              {report.days.map((day) => (
                <EnforcerCountRow
                  key={day.date}
                  label={formatManilaDate(`${day.date}T00:00:00+08:00`)}
                  counts={day}
                />
              ))}
            </EnforcerReportTable>
          </div>
        </>
      )}
    </EnforcerReportPaperFrame>
  );
}
