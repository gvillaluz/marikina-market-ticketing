import Button from "@/components/ui/Button";
import { useId } from "react";
import Modal from "@/components/ui/Modal";
import { usePersonForm } from "../hooks/usePersonForm";
import controls from "@/styles/FormControls.module.css";
import styles from "./PersonFormModal.module.css";

interface Props { open: boolean; personId: number | null; onClose: () => void; onSaved: () => Promise<void>; }

export default function PersonFormModal({ open, personId, onClose, onSaved }: Props) {
  const prefix = useId();
  const state = usePersonForm(open, personId, onSaved, onClose);
  const disabled = state.saving || state.loading || Boolean(state.loadError);
  return (
    <Modal open={open} onClose={onClose} closeDisabled={state.saving} title={personId === null ? "Create person" : "Person details"} subtitle="Independent person record. No login account is created.">
      {state.loading ? <p role="status">Loading person…</p> : state.loadError ? <div role="alert"><p>{state.loadError}</p><Button type="button" variant="secondary" onClick={state.retry}>Try again</Button></div> :
        <form className={styles.form} noValidate onSubmit={event => { event.preventDefault(); void state.submit(); }}>
          <label className={styles.field} htmlFor={`${prefix}-name`}>Full name (required)
            <input id={`${prefix}-name`} className={controls.input} value={state.form.fullName} maxLength={200} disabled={disabled} onChange={event => state.update("fullName", event.target.value)} aria-invalid={Boolean(state.errors.fullName)} aria-describedby={state.errors.fullName ? `${prefix}-name-error` : undefined} />
          </label>
          {state.errors.fullName && <p className={styles.error} id={`${prefix}-name-error`} role="alert">{state.errors.fullName}</p>}
          <label className={styles.field} htmlFor={`${prefix}-address`}>Address (required)
            <textarea id={`${prefix}-address`} className={controls.input} rows={3} value={state.form.address} maxLength={500} disabled={disabled} onChange={event => state.update("address", event.target.value)} aria-invalid={Boolean(state.errors.address)} aria-describedby={state.errors.address ? `${prefix}-address-error` : undefined} />
          </label>
          {state.errors.address && <p className={styles.error} id={`${prefix}-address-error`} role="alert">{state.errors.address}</p>}
          <label className={styles.field} htmlFor={`${prefix}-phone`}>Phone number (optional)
            <input id={`${prefix}-phone`} className={controls.input} type="tel" value={state.form.phoneNumber ?? ""} maxLength={11} disabled={disabled} onChange={event => state.update("phoneNumber", event.target.value)} aria-invalid={Boolean(state.errors.phoneNumber)} aria-describedby={state.errors.phoneNumber ? `${prefix}-phone-error` : undefined} />
          </label>
          {state.errors.phoneNumber && <p className={styles.error} id={`${prefix}-phone-error`} role="alert">{state.errors.phoneNumber}</p>}
          {personId !== null && state.createdAt && <p className={styles.note}>Created {new Date(state.createdAt).toLocaleString("en-PH", { timeZone: "Asia/Manila" })}</p>}
          {state.submitError && <p className={styles.error} role="alert">{state.submitError}</p>}
          {state.uncertainCreate && <div className={styles.recovery} role="alert"><p>The save result is uncertain. Check the person registry in another tab before trying again. Identical names may belong to different people.</p><Button type="button" variant="secondary" onClick={state.confirmNotSaved}>I checked: this person was not saved</Button></div>}
          <div className={styles.actions}>
            <Button type="button" variant="secondary" disabled={state.saving} onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={disabled || state.uncertainCreate}>{state.saving ? "Saving…" : personId === null ? "Create person" : "Save changes"}</Button>
          </div>
        </form>}
    </Modal>
  );
}
