import Modal from "@/components/ui/Modal";
import styles from './TicketModal.module.css';
import brandLogo from '../../../assets/icons/Marikina_City_Seal.svg (1).webp';
import TicketViolationInfoSection from "./modal/TicketViolatorInfoSection";
import TicketViolationDetailsSection from "./modal/TicketViolationDetailsSection";
import TicketPenaltyDetailsSection from "./modal/TicketPenaltyDetailsSection";
import TicketSignatureSection from "./modal/TicketSignatureSection";
import TicketPhotoEvidenceSection from "./modal/TicketPhotoEvidenceSection";
import TicketExportPanel from "./modal/TicketExportPanel";
import { useTicketDetails } from "../hooks/useTicketDetails";
import { toPng } from "html-to-image";
import { useRef } from "react";
import jsPDF from "jspdf";
import { useReactToPrint } from "react-to-print";
import { TicketDetail } from "@/api/types/ticket.types";

interface TicketModalProps {
    isOpen: boolean;
    ticketId: number;
    onClose: () => void;
}

export function TicketModal({ isOpen, ticketId, onClose }: TicketModalProps) {
    const { ticket, isLoading, isError, error } = useTicketDetails(ticketId);
    const ticketPaperRef = useRef<HTMLDivElement>(null);

    const handleExportPNG = async () => {
    if (!ticketPaperRef.current) return;
        try {
            const dataUrl = await toPng(ticketPaperRef.current, {
                quality: 0.95,
                pixelRatio: 2,
                cacheBust: true,
            });

            const link = document.createElement('a');
            link.download = `Violation-Ticket-${ticket?.controlNumber || ticketId}.png`;
            link.href = dataUrl;
            link.click();
        } catch (err) {
            console.error('Failed to export PNG:', err);
        }
    };

    const handleExportPDF = async () => {
        if (!ticketPaperRef.current) return;
        try {
            const dataUrl = await toPng(ticketPaperRef.current, {
                quality: 0.95,
                pixelRatio: 2,
                cacheBust: true,
            });

            const pdf = new jsPDF('p', 'mm', 'a4');
            const pdfWidth = pdf.internal.pageSize.getWidth();
            const pdfHeight = pdf.internal.pageSize.getHeight();

            const imgProps = pdf.getImageProperties(dataUrl);
            
            const widthRatio = pdfWidth / imgProps.width;
            const heightRatio = pdfHeight / imgProps.height;
            const ratio = Math.min(widthRatio, heightRatio);

            const imgWidth = imgProps.width * ratio;
            const imgHeight = imgProps.height * ratio;

            const x = (pdfWidth - imgWidth) / 2;
            const y = (pdfHeight - imgHeight) / 2;

            pdf.addImage(dataUrl, 'PNG', x, y, imgWidth, imgHeight);
            pdf.save(`Violation-Ticket-${ticket?.controlNumber || ticketId}.pdf`);
        } catch (err) {
            console.error('Failed to export PDF:', err);
        }
        };

    const handlePrint = useReactToPrint({
        contentRef: ticketPaperRef,
        pageStyle: `
            @page {
                size: A4 portrait;
                margin: 0;
            }
            @media print {
            body {
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            html, body {
                height: 100%;
                margin: 0 !important;
                padding: 0 !important;
                overflow: hidden;
            }
            /* Scale the ticket container to fit within the printable page height */
            div {
                max-height: 100vh !important;
                box-sizing: border-box !important;
            }
            }
        `,
        });

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
                    <div ref={ticketPaperRef} className={styles.ticketPaper}>
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
                        <TicketSignatureSection
                            enforcerName={`${ticket?.enforcerLastName}, ${ticket?.enforcerFirstName}`}
                            vendorName={`${ticket?.lastName}, ${ticket?.firstName}`}
                        />
                    </div>

                    <TicketPhotoEvidenceSection images={ticket?.ticketEvidences || []} />
                </div>

                <TicketExportPanel
                    onExportPNG={handleExportPNG}
                    onExportPDF={handleExportPDF}
                    onPrint={handlePrint}
                />
            </div>
        </Modal>
    );
}