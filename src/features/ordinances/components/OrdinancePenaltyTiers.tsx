import { Plus, RefreshCw, Undo2 } from "lucide-react";
import { formatCurrency } from "@/utils/formatters";
import type { useOrdinanceEditor } from "../hooks/useOrdinanceEditor";
import PenaltyTierRow from "./PenaltyTierRow";
import PenaltyTiersSkeleton from "./PenaltyTiersSkeleton";
import controls from "./OrdinanceControls.module.css";
import styles from "./OrdinancePenaltyTiers.module.css";

interface Props {
  editor: ReturnType<typeof useOrdinanceEditor>;
}

export default function OrdinancePenaltyTiers({ editor }: Props) {
  return (
    <section
      className={controls.section}
      aria-labelledby="ordinance-tiers-heading"
      aria-busy={editor.isLoadingDetails || editor.isRetryingDetails}
    >
      <header className={styles.header}>
        <div>
          <h4 id="ordinance-tiers-heading" className={controls.sectionTitle}>
            Assigned Penalty Tiers
          </h4>
          <p className={controls.sectionSubtitle}>
            Set the severity and fee for each offense occurrence.
          </p>
        </div>
        <div className={styles.actions}>
          {editor.selected && (
            <button
              type="button"
              className={`${controls.button} ${controls.outline} ${styles.add}`}
              disabled={!editor.canUndo}
              onClick={editor.undo}
            >
              <Undo2 size={12} aria-hidden="true" /> Undo changes
            </button>
          )}
          <button
            type="button"
            className={`${controls.button} ${controls.outline} ${styles.add}`}
            disabled={editor.disabled}
            onClick={editor.addTier}
          >
            <Plus size={12} aria-hidden="true" /> Add Tier
          </button>
        </div>
      </header>
      {editor.isDetailError ? (
        <div className={styles.error} role="alert">
          <p>{editor.detailError}</p>
          <button
            type="button"
            className={`${controls.button} ${controls.outline}`}
            onClick={editor.retryDetails}
            disabled={editor.isRetryingDetails}
          >
            <RefreshCw size={12} aria-hidden="true" />
            {editor.isRetryingDetails ? "Retrying…" : "Try again"}
          </button>
        </div>
      ) : editor.isLoadingDetails ? (
        <PenaltyTiersSkeleton />
      ) : editor.tiers.length === 0 ? (
        <div className={styles.empty}>
          <Plus size={18} aria-hidden="true" />
          <strong>No penalty tiers assigned</strong>
          <span>Use Add Tier to configure the first offense.</span>
        </div>
      ) : (
        <>
          <ol className={styles.list} aria-label="Penalty tiers">
            {editor.tiers.map((tier, index) => (
              <PenaltyTierRow
                key={tier.key}
                tier={tier}
                number={index + 1}
                disabled={editor.disabled}
                errors={editor.tierErrors[tier.key] ?? {}}
                touched={editor.tierTouched[tier.key] ?? {}}
                onChange={(field, value) =>
                  editor.changeTier(tier.key, field, value)
                }
                onBlur={(field) => editor.touchTier(tier.key, field)}
                onRemove={() => editor.removeTier(tier.key)}
              />
            ))}
          </ol>
          <p className={styles.summary}>
            Highest configured fee{" "}
            <strong>{formatCurrency(editor.highestFee)}</strong>
          </p>
        </>
      )}
    </section>
  );
}
