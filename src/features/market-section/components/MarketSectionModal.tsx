import styles from './MarketSectionModal.module.css';
import Modal from "@/components/ui/Modal";
import type { useMarketSectionEditor } from "../hooks/useMarketSectionEditor";

interface Props { editor: ReturnType<typeof useMarketSectionEditor>; }

export default function MarketSectionModal({ editor }: Props) {
  return (
    <Modal open={editor.open} onClose={editor.close} size="sm"
      title={`${editor.selected ? "Edit" : "Add"} Market Section`}
      subtitle="System Configuration"
      footer={<>
        <button type="button" onClick={editor.close} disabled={editor.isSaving}
          className={styles.cancelButton}>Cancel</button>
        <button type="submit" form="market-section-form" disabled={editor.isSaving}
          className={styles.saveButton}>
          {editor.isSaving ? "Saving…" : editor.selected ? "Save Changes" : "Add Section"}
        </button>
      </>}>
      <form id="market-section-form" onSubmit={(event) => { event.preventDefault(); editor.submit(); }} aria-busy={editor.isSaving}>
        <div className={styles.fields}>
          <div>
            <label htmlFor="section-name" className={styles.label}>Section name</label>
            <input id="section-name" autoFocus required value={editor.name} disabled={editor.isSaving}
              onChange={(event) => editor.setName(event.target.value)} placeholder="e.g. Fresh Produce"
              className={styles.input} />
          </div>
          <div>
            <label htmlFor="section-description" className={styles.label}>Description</label>
            <textarea id="section-description" required value={editor.description} disabled={editor.isSaving}
              onChange={(event) => editor.setDescription(event.target.value)} placeholder="Short description of this market area"
              className={styles.textarea} />
          </div>
          {editor.error && <p role="alert" className={styles.error}>{editor.error}</p>}
        </div>
      </form>
    </Modal>
  );
}
