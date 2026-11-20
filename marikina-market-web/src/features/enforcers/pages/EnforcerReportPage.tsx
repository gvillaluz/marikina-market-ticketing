import { FC } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import PageHeader from "@/components/ui/PageHeader";
import Button from "@/components/ui/Button";
import { ROUTES } from "@/routes/routePaths";
import { useEnforcerReport } from "../hooks/useEnforcerReport";
import EnforcerReportPeriod from "../components/report/EnforcerReportPeriod";
import EnforcerReportPreview from "../components/report/EnforcerReportPreview";
import EnforcerReportPaper from "../components/report/EnforcerReportPaper";
import styles from "./EnforcerReportPage.module.css";

const EnforcerReportPage: FC = () => {
  const navigate = useNavigate();
  const model = useEnforcerReport();

  return (
    <div className={styles.page}>
      <PageHeader
        title="Enforcer report"
        subtitle="Warnings, tickets and fines for every enforcer over a chosen period."
        actions={
          <Button
            type="button"
            variant="outline"
            size="sm"
            icon={<ArrowLeft size={14} aria-hidden="true" />}
            onClick={() => navigate(ROUTES.enforcers)}
          >
            Back to Enforcers
          </Button>
        }
      />
      <EnforcerReportPeriod model={model} />
      <EnforcerReportPreview model={model}>
        {model.report && (
          <EnforcerReportPaper report={model.report} paperRef={model.paperRef} />
        )}
      </EnforcerReportPreview>
    </div>
  );
};

export default EnforcerReportPage;
