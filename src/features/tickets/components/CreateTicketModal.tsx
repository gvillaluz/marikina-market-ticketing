import { FC, FormEvent, useState } from 'react';
import Modal from '@/components/ui/Modal';
import Button from '@/components/ui/Button';
import { ticketsApi } from '@/api/endpoints/tickets.api';
import { TICKET_TYPES, TICKET_SEVERITIES, MARIKINA_BARANGAYS } from '@/utils/constants';
import { TICKET_TYPE_LABELS, SEVERITY_LABELS } from '@/utils/constants';
import { isRequired } from '@/utils/validators';
import type { CreateTicketInput } from '@/api/types/ticket.types';
import styles from './CreateTicketModal.module.css';

interface CreateTicketModalProps {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
}

const CreateTicketModal: FC<CreateTicketModalProps> = ({ open, onClose, onCreated }) => {
  const [form, setForm] = useState<CreateTicketInput>({
    type: 'violation',
    title: '',
    description: '',
    severity: 'medium',
    location: MARIKINA_BARANGAYS[0],
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const setField = <K extends keyof CreateTicketInput>(key: K, value: CreateTicketInput[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!isRequired(form.title) || !isRequired(form.description)) {
      setError('Please fill in the title and description.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await ticketsApi.create(form);
      onCreated();
      onClose();
      setForm({ type: 'violation', title: '', description: '', severity: 'medium', location: MARIKINA_BARANGAYS[0] });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create ticket.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Create New Ticket" size="md">
      <form className={styles.form} onSubmit={handleSubmit}>
        {error && <div className={styles.error}>{error}</div>}

        <div className={styles.field}>
          <label className={styles.label}>Ticket Type</label>
          <select
            className={styles.input}
            value={form.type}
            onChange={(e) => setField('type', e.target.value as CreateTicketInput['type'])}
          >
            {TICKET_TYPES.map((t) => (
              <option key={t} value={t}>{TICKET_TYPE_LABELS[t]}</option>
            ))}
          </select>
        </div>

        <div className={styles.field}>
          <label className={styles.label}>Title</label>
          <input
            className={styles.input}
            value={form.title}
            onChange={(e) => setField('title', e.target.value)}
            placeholder="e.g. Expired Business Permit"
          />
        </div>

        <div className={styles.field}>
          <label className={styles.label}>Description</label>
          <textarea
            className={styles.input}
            value={form.description}
            onChange={(e) => setField('description', e.target.value)}
            placeholder="Provide details about the ticket…"
            rows={4}
          />
        </div>

        <div className={styles.row}>
          <div className={styles.field}>
            <label className={styles.label}>Severity</label>
            <select
              className={styles.input}
              value={form.severity}
              onChange={(e) => setField('severity', e.target.value as CreateTicketInput['severity'])}
            >
              {TICKET_SEVERITIES.map((s) => (
                <option key={s} value={s}>{SEVERITY_LABELS[s]}</option>
              ))}
            </select>
          </div>
          <div className={styles.field}>
            <label className={styles.label}>Location (Barangay)</label>
            <select
              className={styles.input}
              value={form.location}
              onChange={(e) => setField('location', e.target.value)}
            >
              {MARIKINA_BARANGAYS.map((b) => (
                <option key={b} value={b}>{b}</option>
              ))}
            </select>
          </div>
        </div>

        <div className={styles.actions}>
          <Button type="button" variant="outline" onClick={onClose}>Cancel</Button>
          <Button type="submit" loading={loading}>Create Ticket</Button>
        </div>
      </form>
    </Modal>
  );
};

export default CreateTicketModal;
