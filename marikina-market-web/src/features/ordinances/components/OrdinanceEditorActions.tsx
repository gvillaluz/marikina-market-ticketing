import Button from "@/components/ui/Button";
import type { useOrdinanceEditor } from "../hooks/useOrdinanceEditor";
import styles from "./OrdinanceEditorActions.module.css";

interface Props {
  editor: ReturnType<typeof useOrdinanceEditor>;
}

export default function OrdinanceEditorActions({ editor }: Props) {
  return (
    <div className={styles.footer}>
      {editor.error && (
        <p className={styles.error} role="alert">
          {editor.error}
        </p>
      )}
      <div className={styles.actions}>
        <Button
          variant="outline"
          type="button"
          disabled={editor.isSaving}
          onClick={editor.close}
        >
          Cancel
        </Button>
        <Button
          type="submit"
          form="ordinance-editor-form"
          disabled={!editor.canSave}
          loading={editor.isSaving}
        >
          {editor.isSaving
            ? "Saving…"
            : editor.selected
              ? "Save Changes"
              : "Create Ordinance"}
        </Button>
      </div>
    </div>
  );
}
