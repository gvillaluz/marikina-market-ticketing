import type { VendorRiskRanking } from "@/api/types/admin-analytics.types";
import AnalyticsPanel from "./AnalyticsPanel";
import styles from "./VendorRiskRankingTable.module.css";

interface VendorRiskRankingTableProps {
  data: VendorRiskRanking[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
}

function severityLabel(value: string | number | null): string {
  if (value == null) return "N/A";
  if (typeof value === "number") {
    return ["Minor", "Moderate", "High"][value] ?? String(value);
  }
  return value.replace(/([a-z])([A-Z])/g, "$1 $2");
}

function severityClass(value: string | number | null): string {
  const severity = severityLabel(value).toLowerCase();
  if (severity.includes("high")) return styles.high;
  if (severity.includes("moderate") || severity.includes("medium")) return styles.moderate;
  if (severity.includes("low") || severity.includes("minor")) return styles.low;
  return styles.neutral;
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
      title="Vendor Risk Ranking"
      subtitle="Vendors ranked by recorded offenses and risk score."
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
              <th scope="col">Business ID</th>
              <th scope="col">Offense Count</th>
              <th scope="col">Highest Severity</th>
              <th scope="col">Risk Score</th>
            </tr>
          </thead>
          <tbody>
            {data.map((vendor) => (
              <tr key={`${vendor.businessId}-${vendor.rank}`}>
                <td>#{vendor.rank}</td>
                <td className={styles.businessName}>{vendor.businessName}</td>
                <td>{vendor.businessId}</td>
                <td>{vendor.offenseCount}</td>
                <td>
                  <span className={`${styles.severity} ${severityClass(vendor.highestSeverity)}`}>
                    {severityLabel(vendor.highestSeverity)}
                  </span>
                </td>
                <td>
                  <span className={`${styles.riskScore} ${riskClass(vendor.riskScore)}`}>
                    {riskLabel(vendor.riskScore)} · {vendor.riskScore}
                  </span>
                </td>
              </tr>
            ))}
            {!isLoading && data.length === 0 && (
              <tr><td className={styles.empty} colSpan={6}>No vendor risk records available.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </AnalyticsPanel>
  );
}
