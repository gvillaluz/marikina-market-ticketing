import Modal from "@/components/ui/Modal";
import styles from './TicketModal.module.css';
import brandLogo from '../../../assets/icons/Marikina_City_Seal.svg (1).webp';
import TicketViolationInfoSection from "./modal/TicketViolatorInfoSection";
import TicketViolationDetailsSection from "./modal/TicketViolationDetailsSection";
import TicketPenaltyDetailsSection from "./modal/TicketPenaltyDetailsSection";
import TicketSignatureSection from "./modal/TicketSignatureSection";
import TicketPhotoEvidenceSection from "./modal/TicketPhotoEvidenceSection";
import TicketExportPanel from "./modal/TicketExportPanel";
import { toPng } from "html-to-image";
import { useRef, useState } from "react";
import { createPortal } from "react-dom";
import jsPDF from "jspdf";
import { useReactToPrint } from "react-to-print";
import TicketModalSkeleton from "./modal/TicketModalSkeleton";
import Button from "@/components/ui/Button";
import { RefreshCw } from "lucide-react";
import { useTicketDetails } from "@/features/tickets/hooks/useTicketDetails";
import { getApiErrorMessage } from "@/utils/apiErrors";

type ExportAction = "png" | "pdf" | "print";

function getErrorMessage(error: unknown): string {
    return getApiErrorMessage(error, "An unexpected error occurred.");
}

function getRecordFileName(ticket: { type: string; controlNumber?: string }, ticketId: number) {
    const recordName = ticket.type === "Ticket" ? "Violation-Ticket" : "Written-Warning";
    const controlNumber = ticket.controlNumber?.replace(/[^\w-]/g, "-") || ticketId;
    return `${recordName}-${controlNumber}`;
}

interface TicketModalProps {
    isOpen: boolean;
    ticketId: number;
    onClose: () => void;
}

export function TicketModal({
    isOpen,
    ticketId,
    onClose,
}: TicketModalProps) {
    const { ticket, isLoading, isError, error, refetch } = useTicketDetails(ticketId, isOpen);
    const ticketPaperRef = useRef<HTMLDivElement>(null);
    const [busyAction, setBusyAction] = useState<ExportAction | null>(null);
    const [exportError, setExportError] = useState<string | null>(null);

    const isTicket = ticket?.type === 'Ticket';

    const handleExportPNG = async () => {
        if (!ticketPaperRef.current || !ticket) return;
        setBusyAction("png");
        setExportError(null);
        try {
            const dataUrl = await toPng(ticketPaperRef.current, {
                quality: 0.95,
                pixelRatio: 2,
                cacheBust: true,
            });

            const link = document.createElement('a');
            link.download = `${getRecordFileName(ticket, ticketId)}.png`;
            link.href = dataUrl;
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (err) {
            setExportError(`Could not create the PNG export. ${getErrorMessage(err)}`);
        } finally {
            setBusyAction(null);
        }
    };

    const handleExportPDF = async () => {
        if (!ticketPaperRef.current || !ticket) return;
        setBusyAction("pdf");
        setExportError(null);
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
            pdf.save(`${getRecordFileName(ticket, ticketId)}.pdf`);
        } catch (err) {
            setExportError(`Could not create the PDF export. ${getErrorMessage(err)}`);
        } finally {
            setBusyAction(null);
        }
    };

    const handlePrint = useReactToPrint({
        contentRef: ticketPaperRef,
        pageStyle: `
            @page {
                size: A4 portrait;
                margin: 10mm;
            }
            @media print {
                body {
                    -webkit-print-color-adjust: exact;
                    print-color-adjust: exact;
                }
                [data-ticket-paper] {
                    width: 100% !important;
                    border: 0 !important;
                    border-radius: 0 !important;
                    box-shadow: none !important;
                    padding: 0 !important;
                }
            }
        `,
        onAfterPrint: () => setBusyAction(null),
        onPrintError: (_location, printError) => {
            setExportError(`Could not print this record. ${getErrorMessage(printError)}`);
            setBusyAction(null);
        },
    });

    const startPrint = () => {
        setBusyAction("print");
        setExportError(null);
        handlePrint();
    };

    return createPortal((
        <Modal
            open={isOpen}
            title="Inspection Record"
            subtitle="Review the record details, evidence, and available export options."
            onClose={onClose}
            size="xlg"
        >
            <div className={styles.layout}>
                <div className={styles.leftColumn}>
                    <div ref={ticketPaperRef} className={styles.ticketPaper} data-ticket-paper>
                        {isLoading ? (
                            <TicketModalSkeleton />
                        ) : isError ? (
                            <div className={styles.ticketError} role="alert">
                                <span>{getApiErrorMessage(error, "Unable to load this inspection record.")}</span>
                                <Button
                                    size="sm"
                                    variant="outline"
                                    icon={<RefreshCw size={14} />}
                                    onClick={() => void refetch()}
                                >
                                    Try again
                                </Button>
                            </div>
                        ) : !ticket ? (
                            <div className={styles.ticketError} role="status">
                                Ticket details are not available.
                            </div>
                        ) : (
                            <>
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
                                        <span className={styles.violationLabel}>{isTicket ? 'VIOLATION TICKET' : 'WRITTEN WARNING TICKET'}</span>
                                    </div>
                                    {isTicket &&
                                    <div className={styles.controlNo}>
                                        <span className={styles.controlLabel}>CONTROL NO.</span>
                                        <span className={styles.controlValue}>{ticket?.controlNumber || "N/A"}</span>
                                    </div>}
                                </div>

                                <hr className={styles.divider} />

                                <TicketViolationInfoSection detail={ticket} />
                                <TicketViolationDetailsSection detail={ticket} />
                                
                                {ticket?.type == 'Ticket' && <TicketPenaltyDetailsSection detail={ticket} />}

                                <TicketSignatureSection
                                    enforcerName={`${ticket?.enforcerLastName}, ${ticket?.enforcerFirstName}`}
                                    vendorName={`${ticket?.lastName}, ${ticket?.firstName}`}
                                />
                            </>
                        )}
                    </div>

                    {isTicket && <TicketPhotoEvidenceSection images={ticket?.ticketEvidences || []} />}
                </div>

                <TicketExportPanel
                    onExportPNG={handleExportPNG}
                    onExportPDF={handleExportPDF}
                    onPrint={startPrint}
                    disabled={isLoading || isError || !ticket}
                    busyAction={busyAction}
                    error={exportError}
                />
            </div>
        </Modal>
    ), document.body);
}