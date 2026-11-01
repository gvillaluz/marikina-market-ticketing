import { Trash2 } from "lucide-react";
import { FINE_KIND_OPTIONS } from "../ordinances.constants";
import { offenseLabel } from "../ordinances.utils";
import type {
  DraftPenaltyTier,
  TierFieldErrors,
  TierFieldName,
} from "../ordinances.types";
import OrdinanceField from "./OrdinanceField";
import OrdinanceOption from "./OrdinanceOption";
import styles from "./PenaltyTierRow.module.css";

interface Props {
  tier: DraftPenaltyTier;
  number: number;
  disabled: boolean;
  errors: TierFieldErrors;
  touched: Partial<Record<TierFieldName, boolean>>;
  onChange: (field: TierFieldName, value: string | boolean) => void;
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
      <div className={styles.header}>
        <div className={styles.offense}>
          <span className={styles.number} aria-hidden="true">
            {number}
          </span>
          <div>
            <strong>{offenseLabel(number)}</strong>
            <span>Penalty tier {number}</span>
          </div>
        </div>
        <button
          type="button"
          className={styles.remove}
          disabled={disabled}
          onClick={onRemove}
          aria-label={`Remove ${offenseLabel(number).toLowerCase()}`}
        >
          <Trash2 size={14} aria-hidden="true" />
        </button>
      </div>
      <div className={styles.fields}>
        <OrdinanceField
          label="Fine rule"
          ariaLabel={`${offenseLabel(number)} fine rule`}
          value={tier.fineKind}
          options={FINE_KIND_OPTIONS}
          disabled={disabled}
          onChange={(value) => onChange("fineKind", value)}
          onBlur={() => onBlur("fineKind")}
          error={touched.fineKind ? errors.fineKind : undefined}
        />
        {tier.fineKind === "Fixed" && (
          <OrdinanceField
            label="Fine amount"
            ariaLabel={`${offenseLabel(number)} fine amount`}
            value={tier.amount}
            placeholder="0.00"
            monetary
            disabled={disabled}
            onChange={(value) => onChange("amount", value)}
            onBlur={() => onBlur("amount")}
            error={touched.amount ? errors.amount : undefined}
          />
        )}
        {tier.fineKind === "UpTo" && (
          <OrdinanceField
            label="Maximum fine amount"
            ariaLabel={`${offenseLabel(number)} maximum fine amount`}
            value={tier.maximumFine}
            placeholder="e.g. 1000.00"
            monetary
            disabled={disabled}
            onChange={(value) => onChange("maximumFine", value)}
            onBlur={() => onBlur("maximumFine")}
            error={touched.maximumFine ? errors.maximumFine : undefined}
          />
        )}
      </div>
      {tier.fineKind === "UpTo" && <p className={styles.note}>Minimum fine: ₱100. The enforcer enters the amount assessed on paper.</p>}
      {tier.fineKind === "Unconfirmed" && <p className={styles.note}>Citation assessment is unavailable until a confirmed fine rule is configured.</p>}
      <OrdinanceField
        label={tier.fineKind === "Unconfirmed" ? "Penalty terms" : "Penalty terms (optional)"}
        ariaLabel={`${offenseLabel(number)} penalty terms`}
        value={tier.penaltyTerms}
        placeholder="Enter penalty wording or conditions"
        multiline
        required={tier.fineKind === "Unconfirmed"}
        disabled={disabled}
        onChange={(value) => onChange("penaltyTerms", value)}
        onBlur={() => onBlur("penaltyTerms")}
        error={touched.penaltyTerms ? errors.penaltyTerms : undefined}
      />
      {number === 1 ? (
        <fieldset className={styles.alternatives} disabled={disabled}>
          <legend>First-offense alternatives</legend>
          <OrdinanceOption label="Blood donation" checked={tier.allowBloodDonation} disabled={disabled}
            onChange={(value) => onChange("allowBloodDonation", value)} />
          <OrdinanceOption label="Community service" checked={tier.allowCommunityService} disabled={disabled}
            onChange={(value) => onChange("allowCommunityService", value)} />
        </fieldset>
      ) : <p className={styles.note}>Alternative penalties are available on the first offense only.</p>}
    </li>
  );
}
