import { FC, useId } from "react";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button/Button";
import SkeletonBlock from "@/components/ui/Skeleton/SkeletonBlock";
import type { PenaltyOptions, PenaltyType } from "@/api/types/ticket.types";
import { formatControlNumberLabel, formatCurrency } from "@/utils/formatters";
import controls from "@/styles/FormControls.module.css";
import { PENALTY_CHANGE_REASONS, PENALTY_CHOICES } from "../../tickets.utils";
import type { PenaltyChangeSelection } from "../../hooks/usePenaltyChangeSelection";
import StatusOptionCard from "./StatusOptionCard";
import styles from "./PenaltyChangeModal.module.css";

const NOT_ALLOWED = "Not allowed for this ticket under the market code";

const choiceDescription = (type: PenaltyType, options: PenaltyOptions) => {
  if (type === "CashFine")
    return `Pay ${formatCurrency(options.cashFineAmount ?? 0)}`;
  if (type === "CommunityService") return "At least 3 hours";
  return "Donate blood instead of paying";
};

interface PenaltyChangeModalProps {
  open: boolean;
  controlNumber: string | null | undefined;
  options: PenaltyOptions | undefined;
  isLoading: boolean;
  error: string | null;
  selection: PenaltyChangeSelection;
  isSaving: boolean;
  onRetry: () => void;
  onConfirm: () => void;
  onClose: () => void;
}

const PenaltyChangeModal: FC<PenaltyChangeModalProps> = ({
  open,
  controlNumber,
  options,
  isLoading,
  error,
  selection,
  isSaving,
  onRetry,
  onConfirm,
  onClose,
}) => {
  const hoursId = useId();
  const hoursErrorId = useId();

  return (
    <Modal
      open={open}
      onClose={onClose}
      closeDisabled={isSaving}
      title="Change penalty"
      subtitle={`Ticket ${formatControlNumberLabel(controlNumber)}`}
      size="sm"
      footer={
        <>
          <Button type="button" variant="outline" onClick={onClose} disabled={isSaving}>
            Cancel
          </Button>
          <Button
            type="button"
            variant="primary"
            loading={isSaving}
            disabled={!selection.canConfirm}
            onClick={onConfirm}
          >
            Confirm
          </Button>
        </>
      }
    >
      <div className={styles.content}>
        <div className={styles.options} aria-busy={isLoading}>
          {isLoading &&
            PENALTY_CHOICES.map((choice) => (
              <SkeletonBlock key={choice.value} height="4.25rem" radius="8px" />
            ))}
          {error && (
            <div className={styles.loadError} role="alert">
              <p className={styles.loadErrorText}>{error}</p>
              <Button type="button" variant="outline" size="sm" onClick={onRetry}>
                Retry
              </Button>
            </div>
          )}
          {options &&
            PENALTY_CHOICES.map((choice) => {
              const allowed = selection.isAllowed(choice.value);
              const isCurrent = choice.value === options.currentPenaltyType;
              const description = allowed
                ? choiceDescription(choice.value, options)
                : NOT_ALLOWED;
              return (
                <StatusOptionCard
                  key={choice.value}
                  title={choice.label}
                  description={isCurrent ? `${description} · Current` : description}
                  selected={selection.selectedPenalty === choice.value}
                  disabled={!allowed}
                  onClick={() => selection.selectPenalty(choice.value)}
                />
              );
            })}
        </div>

        {options && selection.needsHours && (
          <div>
            <label className={controls.label} htmlFor={hoursId}>
              Hours of community service
            </label>
            <input
              id={hoursId}
              className={`${controls.input} ${styles.hoursInput}`}
              type="number"
              inputMode="numeric"
              min={3}
              step={1}
              value={selection.hours}
              onChange={(event) => selection.setHours(event.target.value)}
              aria-invalid={selection.hoursError !== null}
              aria-describedby={selection.hoursError ? hoursErrorId : undefined}
              disabled={isSaving}
            />
            {selection.hoursError && (
              <p id={hoursErrorId} className={styles.fieldError}>
                {selection.hoursError}
              </p>
            )}
          </div>
        )}

        {options && (
          <fieldset className={styles.reasons} disabled={isSaving}>
            <legend className={controls.label}>Reason for the change</legend>
            {PENALTY_CHANGE_REASONS.map((reason) => (
              <label key={reason.value} className={styles.reason}>
                <input
                  type="radio"
                  name="penalty-change-reason"
                  className={styles.radio}
                  value={reason.value}
                  checked={selection.reason === reason.value}
                  onChange={() => selection.setReason(reason.value)}
                />
                <span>{reason.label}</span>
              </label>
            ))}
          </fieldset>
        )}

        {options && <p className={styles.summary}>{selection.summary}</p>}
      </div>
    </Modal>
  );
};

export default PenaltyChangeModal;
