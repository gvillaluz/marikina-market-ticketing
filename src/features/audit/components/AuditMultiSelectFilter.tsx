import { ChevronDown } from "lucide-react";
import { useAuditFilterMenu } from "../hooks/useAuditFilterMenu";
import styles from "./AuditMultiSelectFilter.module.css";

interface AuditMultiSelectFilterProps {
  label: string;
  allLabel: string;
  selectionName: string;
  values: readonly string[];
  options: readonly { value: string; label: string }[];
  onToggle: (value: string) => void;
  onClear: () => void;
  disabled?: boolean;
  className?: string;
}

export default function AuditMultiSelectFilter({
  label,
  allLabel,
  selectionName,
  values,
  options,
  onToggle,
  onClear,
  disabled = false,
  className = "",
}: AuditMultiSelectFilterProps) {
  const menu = useAuditFilterMenu(disabled);
  const triggerLabel =
    values.length === 0
      ? allLabel
      : values.length === 1
        ? options.find((option) => option.value === values[0])?.label
        : `${values.length} ${selectionName}`;
  return (
    <div
      ref={menu.root}
      className={`${styles.filter} ${className}`}
      onBlur={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget as Node | null))
          menu.close();
      }}
      onKeyDown={(event) => {
        if (event.key === "Escape" && menu.open) {
          event.stopPropagation();
          menu.escape();
        }
      }}
    >
      <button
        ref={menu.trigger}
        type="button"
        className={styles.trigger}
        aria-label={label}
        aria-expanded={menu.open}
        aria-controls={menu.open ? menu.menuId : undefined}
        aria-haspopup="dialog"
        disabled={disabled}
        onClick={menu.toggle}
      >
        <span>{triggerLabel}</span>
        <ChevronDown size={15} aria-hidden="true" />
      </button>
      {menu.open && (
        <div
          id={menu.menuId}
          role="dialog"
          aria-label={label}
          className={styles.menu}
        >
          <label className={styles.option}>
            <input
              type="checkbox"
              checked={values.length === 0}
              onChange={onClear}
            />
            <span>{allLabel}</span>
          </label>
          {options.map((option) => (
            <label key={option.value} className={styles.option}>
              <input
                type="checkbox"
                checked={values.includes(option.value)}
                onChange={() => onToggle(option.value)}
              />
              <span>{option.label}</span>
            </label>
          ))}
        </div>
      )}
    </div>
  );
}
