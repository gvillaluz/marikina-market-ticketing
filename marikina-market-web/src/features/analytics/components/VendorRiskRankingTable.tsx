import type { VendorRiskRanking } from "@/api/types/admin-analytics.types";
import { formatSeverityLevel } from "@/utils/formatters";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./VendorRiskRankingTable.module.css";

interface VendorRiskRankingTableProps {
  data: VendorRiskRanking[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

function severityLevelClass(level: number | null): string {
  return level == null ? styles.neutral : styles[`level${level}`];
}

function riskClass(score: number): string {
  if (score >= 70) return styles.highRisk;
  if (score >= 40) return styles.mediumRisk;
  return styles.lowRisk;
}

function riskLabel(score: number): string {
  if (score >= 70) return "High Risk";
  if (score >= 40) return "Moderate Risk";
  return "Low Risk";
}

export default function VendorRiskRankingTable({
  data,
  isLoading,
  isError,
  errorMessage,
  onRetry,
}: VendorRiskRankingTableProps) {
  return (
    <AnalyticsPanel
      title="Business Risk Ranking"
      subtitle="Offenses and Severity Levels are for the selected year. Risk scores and ranking use current compliance."
      skeletonVariant="table"
      isLoading={isLoading}
      isError={isError}
      errorMessage={errorMessage}
      onRetry={onRetry}
      className={styles.panel}
    >
      <div className={styles.tableWrap}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th scope="col">Rank</th>
              <th scope="col">Business Name</th>
              <th scope="col">Business Account Number</th>
              <th scope="col">Offense Count</th>
              <th scope="col">Highest Severity Level</th>
              <th scope="col">Risk Score</th>
            </tr>
          </thead>
          <tbody>
            {data.map((vendor) => (
              <tr key={`${vendor.businessAccountNumber}-${vendor.rank}`}>
                <td>#{vendor.rank}</td>
                <td className={styles.businessName}>{vendor.businessName}</td>
                <td>{vendor.businessAccountNumber}</td>
                <td>{vendor.offenseCount}</td>
                <td>
                  <span
                    className={`${styles.severity} ${severityLevelClass(vendor.highestSeverityLevel)}`}
                  >
                    {vendor.highestSeverityLevel == null
                      ? "N/A"
                      : formatSeverityLevel(vendor.highestSeverityLevel)}
                  </span>
                </td>
                <td>
                  <span
                    className={`${styles.riskScore} ${riskClass(vendor.riskScore)}`}
                  >
                    {riskLabel(vendor.riskScore)} · {vendor.riskScore}
                  </span>
                </td>
              </tr>
            ))}
            {!isLoading && data.length === 0 && (
              <tr>
                <td className={styles.empty} colSpan={6}>
                  No business risk records available.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </AnalyticsPanel>
  );
}
