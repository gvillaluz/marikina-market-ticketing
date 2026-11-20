import { FC } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import PageHeader from "@/components/ui/PageHeader";
import Button from "@/components/ui/Button";
import { RecordsState } from "@/components/ui/Records";
import { ROUTES } from "@/routes/routePaths";
import { useEnforcerActivityReport } from "../hooks/useEnforcerActivityReport";
import EnforcerReportPeriod from "../components/report/EnforcerReportPeriod";
import EnforcerReportPreview from "../components/report/EnforcerReportPreview";
import EnforcerActivityPaper from "../components/report/EnforcerActivityPaper";
import styles from "./EnforcerActivityReportPage.module.css";

const EnforcerActivityReportPage: FC = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const enforcerId = Number(id);
  const isEnforcerId = Number.isInteger(enforcerId) && enforcerId > 0;
  const model = useEnforcerActivityReport(enforcerId);
  const enforcer = isEnforcerId ? model.report?.enforcer : undefined;

  const header = (
    <PageHeader
      title="Enforcer report"
      subtitle={
        enforcer
          ? `${enforcer.lastName}, ${enforcer.firstName} · warnings, tickets and fines over a chosen period.`
          : "Warnings, tickets and fines for one enforcer over a chosen period."
      }
      actions={
        isEnforcerId && (
          <Button
            type="button"
            variant="outline"
            size="sm"
            icon={<ArrowLeft size={14} aria-hidden="true" />}
            onClick={() => navigate(ROUTES.enforcerPerformancePage(String(enforcerId)))}
          >
            Back to performance record
          </Button>
        )
      }
    />
  );

  if (!isEnforcerId) {
    return (
      <div className={styles.page}>
        {header}
        <RecordsState
          title="Enforcer not found"
          message="This link does not match an enforcer. Open the report from the enforcer's performance record."
        />
      </div>
    );
  }

  return (
    <div className={styles.page}>
      {header}
      <EnforcerReportPeriod model={model} />
      <EnforcerReportPreview model={model}>
        {model.report && (
          <EnforcerActivityPaper report={model.report} paperRef={model.paperRef} />
        )}
      </EnforcerReportPreview>
    </div>
  );
};

export default EnforcerActivityReportPage;
