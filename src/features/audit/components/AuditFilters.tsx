import { Search } from "lucide-react";
import { Dropdown } from "@/components/ui/Dropdown/Dropdown";
import {
  AUDIT_DATE_OPTIONS,
  AUDIT_MODULE_OPTIONS,
  AUDIT_RESULT_OPTIONS,
} from "../audit.constants";
import type { AuditLogsModel } from "../hooks/useAuditLogs";
import styles from "./AuditFilters.module.css";
import AuditMultiSelectFilter from "./AuditMultiSelectFilter";

export default function AuditFilters({ model }: { model: AuditLogsModel }) {
  return (
    <div className={styles.filters}>
      <label className={styles.search}>
        <Search size={15} aria-hidden="true" />
        <input
          type="search"
          aria-label="Search audit logs"
          placeholder="Search action, description, or target ID…"
          disabled={model.isExporting}
          maxLength={200}
          value={model.search}
          onChange={(event) => model.changeSearch(event.target.value)}
        />
      </label>
      <AuditMultiSelectFilter
        label="Filter by module"
        allLabel="All modules"
        selectionName="modules"
        className={styles.dropdown}
        values={model.modules}
        options={AUDIT_MODULE_OPTIONS}
        onToggle={model.toggleModule}
        onClear={model.clearModules}
        disabled={model.isExporting}
      />
      <AuditMultiSelectFilter
        label="Filter by result"
        allLabel="All results"
        selectionName="results"
        className={styles.dropdown}
        values={model.results}
        options={AUDIT_RESULT_OPTIONS}
        onToggle={model.toggleResult}
        onClear={model.clearResults}
        disabled={model.isExporting}
      />
      <Dropdown
        ariaLabel="Filter by date range"
        triggerId="audit-date-filter"
        className={styles.dropdown}
        fullWidth
        value={model.dateRange}
        triggerLabel={
          AUDIT_DATE_OPTIONS.find((option) => option.value === model.dateRange)
            ?.label
        }
        options={AUDIT_DATE_OPTIONS}
        onChange={model.changeDateRange}
        disabled={model.isExporting}
      />
    </div>
  );
}
