import { Info } from "lucide-react";
import type { useOrdinanceEditor } from "../hooks/useOrdinanceEditor";
import { CATEGORY_OPTIONS } from "../ordinances.constants";
import OrdinanceField from "./OrdinanceField";
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
          label="Market code"
          value={editor.fields.marketCode}
          placeholder="e.g. BAN-WASTE"
          disabled={editor.disabled}
          onChange={(value) => editor.changeField("marketCode", value)}
          onBlur={() => editor.touchField("marketCode")}
          error={
            editor.touched.marketCode
              ? editor.fieldErrors.marketCode
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
        label="Description"
        value={editor.fields.description}
        placeholder="Summarize the rule and the conduct it covers…"
        multiline
        disabled={editor.disabled}
        onChange={(value) => editor.changeField("description", value)}
        onBlur={() => editor.touchField("description")}
        error={
          editor.touched.description
            ? editor.fieldErrors.description
            : undefined
        }
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
    </section>
  );
}
