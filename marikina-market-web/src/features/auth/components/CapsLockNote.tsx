import { ArrowBigUp } from "lucide-react";
import styles from "./CapsLockNote.module.css";

const CapsLockNote = ({ id }: { id: string }) => (
  <p id={id} className={styles.note} role="status">
    <ArrowBigUp size={16} aria-hidden="true" />
    Caps Lock is on.
  </p>
);

export default CapsLockNote;
