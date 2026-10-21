import { Trash2 } from "lucide-react";
import { SEVERITY_OPTIONS } from "../ordinances.constants";
import { offenseLabel } from "../ordinances.utils";
import type {
  DraftPenaltyTier,
  TierFieldErrors,
  TierFieldName,
} from "../ordinances.types";
import OrdinanceField from "./OrdinanceField";
import styles from "./PenaltyTierRow.module.css";

interface Props {
  tier: DraftPenaltyTier;
  number: number;
  disabled: boolean;
  errors: TierFieldErrors;
  touched: Partial<Record<TierFieldName, boolean>>;
  onChange: (field: TierFieldName, value: string) => void;
  onBlur: (field: TierFieldName) => void;
  onRemove: () => void;
}

export default function PenaltyTierRow({
  tier,
  number,
  disabled,
  errors,
  touched,
  onChange,
  onBlur,
  onRemove,
}: Props) {
  return (
    <li className={styles.row}>
      <div className={styles.offense}>
        <span className={styles.number} aria-hidden="true">
          {number}
        </span>
        <div>
          <strong>{offenseLabel(number)}</strong>
          <span>Penalty tier {number}</span>
        </div>
      </div>
      <OrdinanceField
        label="Severity"
        ariaLabel={`${offenseLabel(number)} severity`}
        value={tier.severity}
        options={SEVERITY_OPTIONS}
        disabled={disabled}
        onChange={(value) => onChange("severity", value)}
        onBlur={() => onBlur("severity")}
        error={touched.severity ? errors.severity : undefined}
      />
      <OrdinanceField
        label="Fee amount"
        ariaLabel={`${offenseLabel(number)} fee amount`}
        value={tier.amount}
        placeholder="0.00"
        monetary
        disabled={disabled}
        onChange={(value) => onChange("amount", value)}
        onBlur={() => onBlur("amount")}
        error={touched.amount ? errors.amount : undefined}
      />
      <button
        type="button"
        className={styles.remove}
        disabled={disabled}
        onClick={onRemove}
        aria-label={`Remove ${offenseLabel(number).toLowerCase()}`}
      >
        <Trash2 size={14} aria-hidden="true" />
      </button>
    </li>
  );
}
