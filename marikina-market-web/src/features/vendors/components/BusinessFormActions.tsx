import { LoaderCircle } from "lucide-react";
import styles from "./BusinessFormActions.module.css";

interface Props { saving: boolean; disabled: boolean; creating: boolean; onClose: () => void; }

export default function BusinessFormActions({ saving, disabled, creating, onClose }: Props) {
  return <div className={styles.actions}>
    <button type="button" onClick={onClose} disabled={saving}>Cancel</button>
    <button type="submit" form="business-form" disabled={disabled}>
      {saving && <LoaderCircle size={16} className={styles.spinner} aria-hidden="true" />}
      {saving ? "Saving…" : creating ? "Create Business" : "Save Changes"}
    </button>
  </div>;
}
