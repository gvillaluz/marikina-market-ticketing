import type { OrdinanceSummary } from "../ordinances.types";
import { formatDate } from "@/utils/formatters";
import { CATEGORY_OPTIONS } from "../ordinances.constants";
import controls from "./OrdinanceControls.module.css";
import styles from "./OrdinanceRegistryRow.module.css";

interface Props {
  ordinance: OrdinanceSummary;
  disabled: boolean;
  onManage: () => void;
}

export default function OrdinanceRegistryRow({
  ordinance,
  disabled,
  onManage,
}: Props) {
  return (
    <tr className={styles.row}>
      <th scope="row" className={styles.identity}>
        <strong>{ordinance.ordinanceNo}</strong>
        <span>{ordinance.title}</span>
      </th>
      <td>
        {CATEGORY_OPTIONS.find((option) => option.value === ordinance.category)
          ?.label ?? ordinance.category}
      </td>
      <td>
        {ordinance.penaltyTierCount}{" "}
        {ordinance.penaltyTierCount === 1 ? "tier" : "tiers"}
      </td>
      <td className={styles.date}>{formatDate(ordinance.updatedAt)}</td>
      <td>
        <span
          className={`${styles.status} ${ordinance.isActive ? styles.active : styles.inactive}`}
        >
          <span className={styles.dot} aria-hidden="true" />
          {ordinance.isActive ? "Active" : "Inactive"}
        </span>
      </td>
      <td className={styles.action}>
        <button
          type="button"
          className={`${controls.button} ${controls.outline} ${styles.manage}`}
          disabled={disabled}
          onClick={onManage}
          aria-label={`Manage ordinance ${ordinance.ordinanceNo}`}
        >
          Manage
        </button>
      </td>
    </tr>
  );
}
