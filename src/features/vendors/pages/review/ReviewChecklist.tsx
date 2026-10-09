import { Circle } from "lucide-react";
import styles from "./ReviewChecklist.module.css";

const items = [
  [
    "Identity matches government ID",
    "Compare the name, date of birth, and portrait",
  ],
  ["Government ID validity", "Check that the ID is current and readable"],
  ["Business permit validity", "Verify the permit year and business name"],
  ["Contact details", "Verify the supplied phone and email"],
  ["Market assignment", "Review the market section and stall"],
  ["Duplicate account search", "Check for an existing vendor account"],
];

export default function ReviewChecklist() {
  return (
    <aside className={styles.checklist}>
      <h2>REVIEW CHECKLIST</h2>
      <p>Complete each control before approval.</p>
      {items.map(([title, description]) => (
        <div className={styles.checklistItem} key={title}>
          <Circle size={14} aria-hidden="true" />
          <div>
            <strong>{title}</strong>
            <span>{description}</span>
          </div>
        </div>
      ))}
    </aside>
  );
}
