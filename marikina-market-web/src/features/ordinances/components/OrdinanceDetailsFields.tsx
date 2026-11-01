import { Info } from "lucide-react";
import type { useOrdinanceEditor } from "../hooks/useOrdinanceEditor";
import { CATEGORY_OPTIONS, SEVERITY_OPTIONS } from "../ordinances.constants";
import OrdinanceField from "./OrdinanceField";
import OrdinanceOption from "./OrdinanceOption";
import controls from "./OrdinanceControls.module.css";
import styles from "./OrdinanceDetailsFields.module.css";

interface Props {
  editor: ReturnType<typeof useOrdinanceEditor>;
}

export default function OrdinanceDetailsFields({ editor }: Props) {
  return (
    <section
      className={controls.section}
      aria-labelledby="ordinance-details-heading"
    >
      <header className={styles.header}>
        <span className={styles.icon}>
          <Info size={13} aria-hidden="true" />
        </span>
        <div>
          <h4 id="ordinance-details-heading" className={controls.sectionTitle}>
            Ordinance details
          </h4>
          <p className={controls.sectionSubtitle}>
            Official identity and market classification.
          </p>
        </div>
      </header>
      <div className={styles.identity}>
        <OrdinanceField
          label="Ordinance number"
          value={editor.fields.ordinanceNumber}
          placeholder="e.g. 028"
          disabled={editor.disabled}
          onChange={(value) => editor.changeField("ordinanceNumber", value)}
          onBlur={() => editor.touchField("ordinanceNumber")}
          error={
            editor.touched.ordinanceNumber
              ? editor.fieldErrors.ordinanceNumber
              : undefined
          }
        />
        <OrdinanceField
          label="Series"
          value={editor.fields.series}
          placeholder="e.g. 2026"
          disabled={editor.disabled}
          onChange={(value) => editor.changeField("series", value)}
          onBlur={() => editor.touchField("series")}
          error={editor.touched.series ? editor.fieldErrors.series : undefined}
        />
        <OrdinanceField
          label="Section of ordinance"
          value={editor.fields.section}
          placeholder="e.g. 53"
          disabled={editor.disabled}
          onChange={(value) => editor.changeField("section", value)}
          onBlur={() => editor.touchField("section")}
          error={
            editor.touched.section
              ? editor.fieldErrors.section
              : undefined
          }
        />
      </div>
      <OrdinanceField
        label="Title"
        value={editor.fields.title}
        placeholder="Enter the official ordinance title"
        disabled={editor.disabled}
        onChange={(value) => editor.changeField("title", value)}
        onBlur={() => editor.touchField("title")}
        error={editor.touched.title ? editor.fieldErrors.title : undefined}
      />
      <OrdinanceField
        label="Category"
        value={editor.fields.category}
        options={CATEGORY_OPTIONS}
        placeholder="Select a category"
        disabled={editor.disabled}
        onChange={(value) => editor.changeField("category", value)}
        onBlur={() => editor.touchField("category")}
        error={
          editor.touched.category ? editor.fieldErrors.category : undefined
        }
      />
      {editor.fields.category === "Others" && (
        <OrdinanceField
          label="Specific category"
          value={editor.fields.specificCategory}
          placeholder="Enter the specific category"
          disabled={editor.disabled}
          onChange={(value) => editor.changeField("specificCategory", value)}
          onBlur={() => editor.touchField("specificCategory")}
          error={
            editor.touched.specificCategory
              ? editor.fieldErrors.specificCategory
              : undefined
          }
        />
      )}
      <OrdinanceField
        label="Scoring severity"
        value={editor.fields.severity}
        options={SEVERITY_OPTIONS}
        placeholder="Select scoring severity"
        disabled={editor.disabled}
        onChange={(value) => editor.changeField("severity", value)}
        onBlur={() => editor.touchField("severity")}
        error={editor.touched.severity ? editor.fieldErrors.severity : undefined}
      />
      <p className={styles.explanation}>Severity affects compliance scoring only.</p>
      <OrdinanceOption
        label="Include in the warning ordinance list"
        checked={editor.fields.warningEligible}
        disabled={editor.disabled}
        onChange={(value) => editor.changeField("warningEligible", value)}
      />
    </section>
  );
}
