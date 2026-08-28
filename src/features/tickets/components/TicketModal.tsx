import Modal from "@/components/ui/Modal";
import styles from './TicketModal.module.css';
import brandLogo from '../../../assets/icons/Marikina_City_Seal.svg (1).webp';
import TicketViolationInfoSection from "./TicketViolatorInfoSection";
import TicketViolationDetailsSection from "./TicketViolationDetailsSection";
import TicketPenaltyDetailsSection from "./TicketPenaltyDetailsSection";
import TicketSignatureSection from "./TicketSignatureSection";
import TicketPhotoEvidenceSection from "./TicketPhotoEvidenceSection";
import TicketExportPanel from "./TicketExportPanel";
import { useTicketDetails } from "../hooks/useTicketDetails";

interface TicketModalProps {
    isOpen: boolean,
    ticketId: number,
    onClose: () => void
}

export function TicketModal({ isOpen, ticketId, onClose }: TicketModalProps) {
    const { ticket, isLoading, isError, error } = useTicketDetails(ticketId);

    return (
        <Modal
            open={isOpen}
            title="Ticket Record"
            subtitle="Here is the record of the collected violation ticket. You can review the details below."
            onClose={onClose}
            size="xlg"
        >
            <div className={styles.layout}>
                <div className={styles.leftColumn}>
                    <div className={styles.ticketPaper}>
                        <div className={styles.ticketHeader}>
                            <h4>City of Marikina</h4>
                            <p>Marikina City Public Market</p>
                        </div>
                        <div className={styles.ticketTop}>
                            <div className={styles.brand}>
                                <img
                                    className={styles.logo}
                                    src={brandLogo}
                                    alt="Marikina City Public Market Seal"
                                />
                                <span className={styles.violationLabel}>VIOLATION TICKET</span>
                            </div>
                            <div className={styles.controlNo}>
                                <span className={styles.controlLabel}>CONTROL NO.</span>
                                <span className={styles.controlValue}>{`#${ticket?.controlNumber}`}</span>
                            </div>
                        </div>

                        <hr className={styles.divider} />

                        <TicketViolationInfoSection detail={ticket} />
                        <TicketViolationDetailsSection detail={ticket} />
                        <TicketPenaltyDetailsSection detail={ticket} />
                        <TicketSignatureSection />
                    </div>

                    <TicketPhotoEvidenceSection />
                </div>

                <TicketExportPanel />
            </div>
        </Modal>
    );
}