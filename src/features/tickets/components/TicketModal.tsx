import Modal from "@/components/ui/Modal";
import styles from './CreateTicketModal.module.css';

interface TicketModalProps {
    isOpen: boolean,
    ticketId: number | null,
    onClose: () => void
}

export function TicketModal({ isOpen, ticketId, onClose }: TicketModalProps) {
    return (
        <Modal
            open={isOpen}
            title="TicketRecord"
            subtitle="Here is the record of the collected violation ticket. You can review the details below."
            onClose={onClose}
            size="lg"
        >
            <div className={styles.layout}>
                <div className={styles.ticketPaper}>
                    <div className={styles.ticketHeader}>
                        <h4>City of Marikina</h4>
                    </div>
                </div>
            </div>
        </Modal>
    );
}