import styles from './MarketSectionRow.module.css';
import { Pencil } from "lucide-react";
import type { MarketSectionResponse } from "@/api/types/market-section.types";

interface MarketSectionRowProps {
  section: MarketSectionResponse;
  disabled: boolean;
  pending: boolean;
  onEdit: () => void;
  onToggle: () => void;
}

export default function MarketSectionRow({ section, disabled, pending, onEdit, onToggle }: MarketSectionRowProps) {
  return (
    <tr aria-busy={pending}>
      <th scope="row" className={styles.nameCell}>{section.name}</th>
      <td className={styles.descriptionCell}>{section.description}</td>
      <td className={styles.valueCell}>{section.vendorCount.toLocaleString()}</td>
      <td className={styles.valueCell}>
        <span className={section.isActive ? styles.activeStatus : styles.inactiveStatus}>
          <span className={styles.statusDot} aria-hidden="true" />
          {section.isActive ? "Active" : "Inactive"}
        </span>
      </td>
      <td className={styles.valueCell}>
        <div className={styles.actions}>
          <button
            type="button"
            className={styles.editButton}
            disabled={disabled}
            onClick={onEdit}
            aria-label={`Edit ${section.name}`}
          >
            <Pencil size={14} aria-hidden="true" />
          </button>
          <button
            type="button"
            role="switch"
            aria-checked={section.isActive}
            aria-label={`${section.name} active status`}
            onClick={onToggle}
            aria-busy={pending}
            title={pending ? "Updating status…" : section.isActive ? "Mark inactive" : "Mark active"}
            className={section.isActive ? styles.activeSwitch : styles.inactiveSwitch}
            disabled={disabled}
          >
            <span className={styles.switchKnob} aria-hidden="true" />
          </button>
        </div>
      </td>
    </tr>
  );
}
