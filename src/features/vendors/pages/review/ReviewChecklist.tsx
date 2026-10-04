import { CheckCircle2 } from "lucide-react";
import styles from "../AdminVendorRegistrationReviewPage.module.css";

const items = [
  [
    "Identity matches government ID",
    "Name, date of birth, and portrait verified",
  ],
  ["Government ID is valid", "ID appears current and unobscured"],
  ["Business permit is valid", "Permit year and business name confirmed"],
  ["Contact details verified", "Phone and email from contact confirmed"],
  ["Market assignment confirmed", "Market section and stall reviewed"],
  ["Duplicate account search", "No duplicate found"],
];

export default function ReviewChecklist() {
  return (
    <aside className={styles.checklist}>
      <h2>REVIEW CHECKLIST</h2>
      <p>Complete each control before approval.</p>
      {items.map(([title, description]) => (
        <div className={styles.checklistItem} key={title}>
          <CheckCircle2 size={14} />
          <div>
            <strong>{title}</strong>
            <span>{description}</span>
          </div>
        </div>
      ))}
    </aside>
  );
}
