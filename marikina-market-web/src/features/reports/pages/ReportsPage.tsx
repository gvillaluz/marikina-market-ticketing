import PageHeader from "@/components/ui/PageHeader";
import { useReports } from "../hooks/useReports";
import ReportGenerator from "../components/ReportGenerator";
import ReportPreview from "../components/ReportPreview";
import ReportHistory from "../components/ReportHistory";
import styles from "./ReportsPage.module.css";

export default function ReportsPage() {
  const reports = useReports();
  return (
    <div className={styles.page}>
      <PageHeader
        title="Reports"
        subtitle="Generate and download official inspection and enforcement reports."
        className={styles.header}
      />
      <ReportGenerator reports={reports} />
      <ReportPreview reports={reports} />
      <ReportHistory
        history={reports.history}
        onView={reports.view}
        viewDisabled={reports.generating}
      />
    </div>
  );
}
