import PageHeader from "@/components/ui/PageHeader";
import AnalyticsYearFilter from "../components/AnalyticsYearFilter";
import {
  InspectionRatioCard,
  ResolutionRateCard,
} from "../components/AnalyticsSummaryCards";
import HotspotRankingTable from "../components/HotspotRankingTable";
import MarketSectionAggregationChart from "../components/MarketSectionAggregationChart";
import PeakViolationHeatmap from "../components/PeakViolationHeatmap";
import VendorRiskRankingTable from "../components/VendorRiskRankingTable";
import ViolationTrendChart from "../components/ViolationTrendChart";
import ViolationTypeDistribution from "../components/ViolationTypeDistribution";
import { useAdminAnalyticsPage } from "../hooks/useAdminAnalyticsPage";
import styles from "./AdminAnalyticsPage.module.css";

export default function AdminAnalyticsPage() {
  const analytics = useAdminAnalyticsPage();

  return (
    <div className={styles.page}>
      <PageHeader
        title="Violation Analytics"
        subtitle={
          analytics.yearControl.year === analytics.yearControl.currentYear
            ? "Year-to-date violation counts and trends in Manila time."
            : `January–December ${analytics.yearControl.year} · Violation counts and trends in Manila time.`
        }
        actions={<AnalyticsYearFilter {...analytics.yearControl} />}
      />

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>TIME-BASED ANALYSIS</h2>
        <div className={styles.analyticsGrid}>
          <ViolationTrendChart
            {...analytics.trend}
            onRetry={() => void analytics.trend.refetch()}
          />
          <PeakViolationHeatmap
            {...analytics.peakTimes}
            onRetry={() => void analytics.peakTimes.refetch()}
          />
        </div>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>FREQUENCY DISTRIBUTION</h2>
        <div className={styles.analyticsGrid}>
          <ViolationTypeDistribution
            {...analytics.distribution}
            onRetry={() => void analytics.distribution.refetch()}
          />
          <InspectionRatioCard
            {...analytics.inspectionRatio}
            onRetry={() => void analytics.inspectionRatio.refetch()}
          />
          <ResolutionRateCard
            {...analytics.resolutionRate}
            onRetry={() => void analytics.resolutionRate.refetch()}
          />
        </div>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>AGGREGATION AND RANKING</h2>
        <div className={styles.analyticsGrid}>
          <MarketSectionAggregationChart
            {...analytics.marketSections}
            onRetry={() => void analytics.marketSections.refetch()}
          />
          <HotspotRankingTable
            {...analytics.hotspots}
            comparisonLabel={
              analytics.yearControl.year === analytics.yearControl.currentYear
                ? "Compared with the same period last year."
                : `Compared with January–December ${analytics.yearControl.year - 1}.`
            }
            onRetry={() => void analytics.hotspots.refetch()}
          />
        </div>
      </section>

      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>RISK-BASED RANKING</h2>
        <div className={styles.analyticsGrid}>
          <VendorRiskRankingTable
            {...analytics.vendorRisk}
            onRetry={() => void analytics.vendorRisk.refetch()}
          />
        </div>
      </section>
    </div>
  );
}
