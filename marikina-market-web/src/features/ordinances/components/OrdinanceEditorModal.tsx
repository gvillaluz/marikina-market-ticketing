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
      closeDisabled={editor.isSaving}
      size="md"
      title={editor.selected ? "Edit Ordinance" : "Create Ordinance"}
      footer={<OrdinanceEditorActions editor={editor} />}
    >
      <form
        id="ordinance-editor-form"
        className={styles.form}
        noValidate
        aria-busy={editor.isSaving || editor.isLoadingDetails}
        onSubmit={(event) => {
          event.preventDefault();
          const form = event.currentTarget;
          editor.submit();
          // After the problem fields turn red, move to the first one (this also scrolls it into view).
          requestAnimationFrame(() =>
            form.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus(),
          );
        }}
      >
        <OrdinanceDetailsFields editor={editor} />
        <OrdinancePenaltyTiers editor={editor} />
      </form>
    </Modal>
  );
}
