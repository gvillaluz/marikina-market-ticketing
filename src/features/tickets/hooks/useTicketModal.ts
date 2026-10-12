import { useRef, useState } from "react";
import { toPng } from "html-to-image";
import jsPDF from "jspdf";
import { useReactToPrint } from "react-to-print";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { useTicketDetails } from "./useTicketDetails";

type ExportAction = "png" | "pdf" | "print";

function getErrorMessage(error: unknown): string {
  return getApiErrorMessage(error, "An unexpected error occurred.");
}

function getRecordFileName(
  ticket: { type: string; controlNumber?: string },
  ticketId: number,
) {
  const recordName =
    ticket.type === "Ticket" ? "Violation-Ticket" : "Written-Warning";
  const controlNumber =
    ticket.controlNumber?.replace(/[^\w-]/g, "-") || ticketId;
  return `${recordName}-${controlNumber}`;
}

export function useTicketModal(ticketId: number, isOpen: boolean) {
  const { ticket, isLoading, isError, error, refetch } = useTicketDetails(
    ticketId,
    isOpen,
  );
  const ticketPaperRef = useRef<HTMLDivElement>(null);
  const [busyAction, setBusyAction] = useState<ExportAction | null>(null);
  const [exportError, setExportError] = useState<string | null>(null);

  const isTicket = ticket?.type === "Ticket";

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

      const link = document.createElement("a");
      link.download = `${getRecordFileName(ticket, ticketId)}.png`;
      link.href = dataUrl;
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (err) {
      setExportError(
        `Could not create the PNG export. ${getErrorMessage(err)}`,
      );
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

      const pdf = new jsPDF("p", "mm", "a4");
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

      pdf.addImage(dataUrl, "PNG", x, y, imgWidth, imgHeight);
      pdf.save(`${getRecordFileName(ticket, ticketId)}.pdf`);
    } catch (err) {
      setExportError(
        `Could not create the PDF export. ${getErrorMessage(err)}`,
      );
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
      setExportError(
        `Could not print this record. ${getErrorMessage(printError)}`,
      );
      setBusyAction(null);
    },
  });

  const startPrint = () => {
    setBusyAction("print");
    setExportError(null);
    handlePrint();
  };

  return {
    ticket,
    isLoading,
    isError,
    error,
    refetch,
    ticketPaperRef,
    busyAction,
    exportError,
    isTicket,
    handleExportPNG,
    handleExportPDF,
    startPrint,
  };
}
