import Modal from "@/components/ui/Modal";
import type { useOrdinanceEditor } from "../hooks/useOrdinanceEditor";
import OrdinanceDetailsFields from "./OrdinanceDetailsFields";
import OrdinancePenaltyTiers from "./OrdinancePenaltyTiers";
import OrdinanceEditorActions from "./OrdinanceEditorActions";
import styles from "./OrdinanceEditorModal.module.css";

interface Props {
  editor: ReturnType<typeof useOrdinanceEditor>;
}

export default function OrdinanceEditorModal({ editor }: Props) {
  return (
    <Modal
      open={editor.open}
      onClose={editor.close}
      size="md"
      title={editor.selected ? "Manage Ordinance" : "Create Ordinance"}
      footer={<OrdinanceEditorActions editor={editor} />}
    >
      <form
        id="ordinance-editor-form"
        className={styles.form}
        aria-busy={editor.isSaving || editor.isLoadingDetails}
        onSubmit={(event) => {
          event.preventDefault();
          editor.submit();
        }}
      >
        <OrdinanceDetailsFields editor={editor} />
        <OrdinancePenaltyTiers editor={editor} />
        {editor.error && (
          <p className={styles.error} role="alert">
            {editor.error}
          </p>
        )}
      </form>
    </Modal>
  );
}
