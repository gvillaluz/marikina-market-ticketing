import Breadcrumb from "@/components/ui/Breadcrumb";
import { FileText, Plus } from "lucide-react";

import { ROUTES } from "@/routes/routePaths";
import PageHeader from "@/components/ui/PageHeader";
import { useOrdinances } from "../hooks/useOrdinances";
import { useOrdinanceEditor } from "../hooks/useOrdinanceEditor";
import OrdinanceRegistry from "../components/OrdinanceRegistry";
import OrdinanceEditorModal from "../components/OrdinanceEditorModal";
import controls from "../components/OrdinanceControls.module.css";
import styles from "./OrdinancesPage.module.css";

export default function OrdinancesPage() {
  const directory = useOrdinances();
  const editor = useOrdinanceEditor();
  return (
    <div className={styles.page}>
      <Breadcrumb
        items={[
          { label: "System Configuration", to: ROUTES.systemConfiguration },
          { label: "Ordinances & Penalties" },
        ]}
      />
      <PageHeader
        className={styles.header}
        title="Ordinances & Penalties"
        subtitle="Maintain enforceable rules and offense-based penalty tiers."
        actions={
          <button
            type="button"
            className={`${controls.button} ${controls.primary} ${styles.create}`}
            disabled={
              !editor.canManage ||
              !directory.hasData ||
              editor.isSaving ||
              editor.open
            }
            onClick={() => editor.launch()}
          >
            <Plus size={15} aria-hidden="true" />
            New Ordinance
          </button>
        }
      />
      <OrdinanceRegistry
        directory={directory}
        disabled={!editor.canManage || editor.isSaving || editor.open}
        onManage={editor.launch}
      />
      <aside className={styles.notice}>
        <span className={styles.noticeIcon}>
          <FileText size={19} aria-hidden="true" />
        </span>
        <div>
          <h2>How penalty tiers work</h2>
          <p>
            Set one amount and severity for each offense number. Ticket totals
            are calculated from the applicable tier.
          </p>
        </div>
      </aside>
      <OrdinanceEditorModal editor={editor} />
    </div>
  );
}
