import styles from "./MarketSectionModal.module.css";
import Modal from "@/components/ui/Modal";
import Button from "@/components/ui/Button";
import type { useMarketSectionEditor } from "../hooks/useMarketSectionEditor";

interface Props {
  editor: ReturnType<typeof useMarketSectionEditor>;
}

export default function MarketSectionModal({ editor }: Props) {
  return (
    <Modal
      open={editor.open}
      onClose={editor.close}
      closeDisabled={editor.isSaving}
      size="sm"
      title={`${editor.selected ? "Edit" : "Add"} Market Street`}
      subtitle="Used when choosing a street for businesses, registration and tickets."
      footer={
        <>
          <Button
            variant="outline"
            type="button"
            onClick={editor.close}
            disabled={editor.isSaving}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form="market-section-form"
            disabled={!editor.canSave}
            loading={editor.isSaving}
          >
            {editor.isSaving
              ? "Saving…"
              : editor.selected
                ? "Save Changes"
                : "Add Street"}
          </Button>
        </>
      }
    >
      <form
        id="market-section-form"
        className={styles.form}
        noValidate
        onSubmit={(event) => {
          event.preventDefault();
          editor.submit();
        }}
        aria-busy={editor.isSaving}
      >
        <label htmlFor="section-name" className={styles.label}>
          Street name
        </label>
        <input
          id="section-name"
          required
          maxLength={150}
          value={editor.name}
          disabled={editor.isSaving}
          onChange={(event) => editor.setName(event.target.value)}
          placeholder="e.g. J. P. Rizal"
          aria-invalid={Boolean(editor.error)}
          aria-describedby={editor.error ? "section-name-error" : undefined}
          className={styles.input}
        />
        {editor.error && (
          <p id="section-name-error" role="alert" className={styles.error}>
            {editor.error}
          </p>
        )}
      </form>
    </Modal>
  );
}
