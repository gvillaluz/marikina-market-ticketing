import type { useOrdinanceEditor } from "../hooks/useOrdinanceEditor";
import controls from "./OrdinanceControls.module.css";
import styles from "./OrdinanceEditorActions.module.css";

interface Props {
  editor: ReturnType<typeof useOrdinanceEditor>;
}

export default function OrdinanceEditorActions({ editor }: Props) {
  return (
    <div className={styles.actions}>
      <button
        type="button"
        className={`${controls.button} ${controls.outline}`}
        disabled={editor.isSaving}
        onClick={editor.close}
      >
        Cancel
      </button>
      <button
        type="submit"
        form="ordinance-editor-form"
        className={`${controls.button} ${controls.primary}`}
        disabled={!editor.canSave}
      >
        {editor.isSaving ? "Saving…" : "Save Ordinance"}
      </button>
    </div>
  );
}
